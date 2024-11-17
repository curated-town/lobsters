#!/bin/bash

# Used for simple logging purposes
timestamp="date +\"%Y-%m-%d %H:%M:%S\""
alias echo="echo \"$(eval $timestamp) -$@\""

# Set working directory
cd /srv/lobste.rs/http

# Get current state of database
db_version=$(bundle exec rake db:version)
db_status=$?
echo "DB Version: ${db_version}"

# Provision Database
if [ "$db_status" != "0" ]; then
	echo "Creating database."
	bundle exec rake db:create
	echo "Loading schema."
	bundle exec rake db:schema:load
	echo "Migrating database."
	bundle exec rake db:migrate
	echo "Seeding database."
	bundle exec rake db:seed
elif [[ "$db_version" == *"Current version: 0"* ]]; then
	echo "Loading schema."
	bundle exec rake db:schema:load
	echo "Migrating database."
	bundle exec rake db:migrate
	echo "Seeding database."
	bundle exec rake db:seed
else
	echo "Migrating database."
	bundle exec rake db:migrate
fi

# Set our SECRET_KEY
if [ "$SECRET_KEY_BASE" = "" ]; then
	echo "No SECRET_KEY_BASE provided, generating one now."
	export SECRET_KEY_BASE=$(bundle exec rake secret)
	echo "Your new secret key: $SECRET_KEY_BASE"
fi

# Compile our assets
if [ "$RAILS_ENV" = "production" ]; then
	bundle exec rake assets:precompile
fi

# Start the rails application
cd /srv/lobste.rs/http && bundle exec rails server -b 0.0.0.0 &
pid="$!"
trap "echo 'Stopping Lobsters - pid: $pid'; kill -SIGTERM $pid" SIGINT SIGTERM

# Run the cron job every 5 minutes
while :; do
	echo "Running cron jobs."
	cd /srv/lobste.rs/http && bundle exec ruby script/mail_new_activity.rb
	sleep 300
done &

# Wait for process to end
while kill -0 $pid >/dev/null 2>&1; do
	wait
done

echo "Exiting"
