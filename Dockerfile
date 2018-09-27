FROM circleci/elixir:1.6

USER root

RUN echo "deb [trusted=yes] https://teamweek-packages.s3.amazonaws.com/debian stable main" \
      | tee /etc/apt/sources.list.d/teamweek_packages.list
RUN apt-get install apt-transport-https
RUN apt-get update
RUN apt-get install -y \
    postgresql-client-9.6 \
    wkhtmltopdf \
    apt-transport-s3 \
    libodbc1 \
    libsctp1 \
    libwxgtk3.0 \
    unixodbc-dev \
    libsctp-dev \
    libwxgtk3.0-dev
RUN echo "deb [trusted=yes] s3://teamweek-private-packages.s3.amazonaws.com/debian stable main" \
      | tee /etc/apt/sources.list.d/teamweek_private_packages.list
RUN echo -e "AccessKeyId = $AWS_ACCESS_KEY_ID\nSecretAccessKey = $AWS_SECRET_ACCESS_KEY\nToken = ''" \
      | tee /etc/apt/s3auth.conf > /dev/null

USER circleci
