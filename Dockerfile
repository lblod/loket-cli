FROM ruby:2.6
COPY . /app
WORKDIR /app
ENV EXPORT_PATH /data
RUN bundle
ENTRYPOINT ["bundle", "exec","rake"]
CMD ["create_admin_unit"]