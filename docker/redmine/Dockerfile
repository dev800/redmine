FROM dev800/redmine-container:latest

# explicitly set uid/gid to guarantee that it won't change in the future
# the values 999:999 are identical to the current user/group id assigned
# RUN groupadd -r -g 999 redmine && useradd -r -g redmine -u 999 redmine

ENV TIME_ZONE $TIME_ZONE
ENV RAILS_ENV production

WORKDIR /usr/src/redmine

# https://github.com/docker-library/redmine/issues/138#issuecomment-438834176
# (bundler needs this for running as an arbitrary user)
ENV HOME /home/redmine
RUN set -eux; \
	[ ! -d "$HOME" ]; \
	mkdir -p "$HOME"; \
	chown redmine:redmine "$HOME"; \
	chmod 1777 "$HOME"

ENV REDMINE_VERSION 4.0.17
ENV REDMINE_DOWNLOAD_MD5 e38bfb71472f730a12f5be940b0efae4

RUN set -eux; \
	wget -O redmine.tar.gz "https://github.com/dev800/redmine/archive/v${REDMINE_VERSION}.tar.gz"; \
	echo "$REDMINE_DOWNLOAD_MD5 *redmine.tar.gz" | md5sum -c -; \
	tar -xf redmine.tar.gz --strip-components=1; \
	rm redmine.tar.gz files/delete.me log/delete.me; \
	mkdir -p log public/plugin_assets sqlite tmp/pdf tmp/pids; \
	chown -R redmine:redmine ./; \
	echo 'config.logger = Logger.new(STDOUT)' > config/additional_environment.rb; \
	chmod -R ugo=rwX config db sqlite; \
	find log tmp -type d -exec chmod 1777 '{}' +

RUN set -eux; \
  \
	gosu redmine bundle install -V --jobs "$(nproc)" --without development test; \
	for adapter in mysql2 postgresql sqlserver sqlite3; do \
		echo "$RAILS_ENV:" > ./config/database.yml; \
		echo "  adapter: $adapter" >> ./config/database.yml; \
		gosu redmine bundle install --jobs "$(nproc)" --without development test; \
		cp Gemfile.lock "Gemfile.lock.${adapter}"; \
	done; \
	rm ./config/database.yml; \
	chmod -R ugo=rwX Gemfile.lock "$GEM_HOME";

VOLUME /usr/src/redmine/files
VOLUME /usr/src/redmine/log

COPY docker-entrypoint.sh /
RUN ["chmod", "+x", "/docker-entrypoint.sh"] /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
