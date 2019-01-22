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

USER circleci

RUN gem install fpm; \
    gem install deb-s3

ENV OTP_VERSION 21.2.3
ENV ELIXIR_VERSION 1.8.0

RUN mkdir -p /home/circleci/tools; \
    cd /home/circleci/tools; \
    wget "http://www.erlang.org/download/otp_src_$OTP_VERSION.tar.gz"; \
    tar zxf otp_src_$OTP_VERSION.tar.gz; \
    cd ./otp_src_$OTP_VERSION; \
    ./configure --prefix /home/circleci/tools/otp-$OTP_VERSION --without-javac; \
    make && make install; \
    cd ..; \
    wget "https://github.com/elixir-lang/elixir/releases/download/v$ELIXIR_VERSION/Precompiled.zip"; \
    unzip ./Precompiled.zip -d ./elixir-$ELIXIR_VERSION

ENV PATH "/usr/local/bundle/bin:/usr/local/bundle/gems/bin:/home/circleci/tools/otp-$OTP_VERSION/bin:/home/circleci/tools/elixir-$ELIXIR_VERSION/bin:$PATH"

RUN mix local.rebar --force; \
    mix local.hex --force
