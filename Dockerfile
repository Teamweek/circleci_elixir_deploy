FROM circleci/ruby:2.4-node

USER root

RUN apt-get install -y apt-transport-https

RUN echo "deb [trusted=yes] https://teamweek-packages.s3.amazonaws.com/debian stable main" \
      | tee /etc/apt/sources.list.d/teamweek_packages.list

RUN apt-get update; \
    apt-get install -y \
      apt-transport-s3 \
      libodbc1 \
      libsctp1 \
      libwxgtk3.0 \
      unixodbc-dev \
      libsctp-dev \
      libwxgtk3.0-dev

RUN echo "deb [trusted=yes] s3://teamweek-private-packages.s3.amazonaws.com/debian stable main" \
      | tee /etc/apt/sources.list.d/teamweek_private_packages.list; \
    echo -e "AccessKeyId = $AWS_ACCESS_KEY_ID\nSecretAccessKey = $AWS_SECRET_ACCESS_KEY\nToken = ''" \
      | tee /etc/apt/s3auth.conf > /dev/null

RUN gem install fpm; \
    gem install deb-s3

ENV OTP_VERSION="20.3.8.9"

# We'll install the build dependencies for erlang-odbc along with the erlang
# build process:
RUN set -xe \
	&& OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" \
	&& OTP_DOWNLOAD_SHA256="897dd8b66c901bfbce09ed64e0245256aca9e6e9bdf78c36954b9b7117192519" \
	&& runtimeDeps='libodbc1 \
			libsctp1 \
			libwxgtk3.0' \
	&& buildDeps='unixodbc-dev \
			libsctp-dev \
			libwxgtk3.0-dev' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $runtimeDeps \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
	&& echo "$OTP_DOWNLOAD_SHA256  otp-src.tar.gz" | sha256sum -c - \
	&& export ERL_TOP="/usr/src/otp_src_${OTP_VERSION%%@*}" \
	&& mkdir -vp $ERL_TOP \
	&& tar -xzf otp-src.tar.gz -C $ERL_TOP --strip-components=1 \
	&& rm otp-src.tar.gz \
	&& ( cd $ERL_TOP \
	  && ./otp_build autoconf \
	  && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	  && ./configure --build="$gnuArch" \
	  && make -j$(nproc) \
	  && make install ) \
	&& find /usr/local -name examples | xargs rm -rf \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf $ERL_TOP /var/lib/apt/lists/*
      
ENV ELIXIR_VERSION="v1.6.0" \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
	&& ELIXIR_DOWNLOAD_SHA256="74507b0646bf485ee3af0e7727e3fdab7123f1c5ecf2187a52a928ad60f93831" \
	&& curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
	&& echo "$ELIXIR_DOWNLOAD_SHA256  elixir-src.tar.gz" | sha256sum -c - \
	&& mkdir -p /usr/local/src/elixir \
	&& tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz \
	&& rm elixir-src.tar.gz \
	&& cd /usr/local/src/elixir \
	&& make install clean

USER circleci

RUN mix local.rebar --force; \
    mix local.hex --force
