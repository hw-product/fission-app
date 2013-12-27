# Fission App

Web application front end and user manager.

## About

This is a Rails application and framework for the website to manage users and track build
information. Allowing the creation and management of user data and permissions of what
each user can perform when building packages. Rails application is supported by a riak
database.

## Getting Started

1. Install ruby and rails
  * add-apt-repository ppa:brightbox/ruby-ng
2. clone repository
  * git clone https://github.com/heavywater/fission-app
3. Change to repository directory
  * `bundle install --path vendor`
  * `bundle --binstubs`
4. Install riak
  * Riak cookbook is easy way to get instance stood up
5. Create JSON file for database with contents (riak.json):

```json
{"nodes": [{"host": "IP_ADDRESS"}]}
```
6. FISSION_RIAK_CONFIG=riak.json ./bin/rails s

### Helpful testing things:

* ALLOW_NO_AUTH=true - defaults to first user on request
* Sending JSON requests:
  * `curl http://localhost:3000/users/6 -H "Accept: application/json"`

## Usage examples

Run rails application. Do website stuff.

### Start without database

```
FISSION_DATA=false ./bin/rails s
```

It's important to note most of the app will not work.

### Using local repository checkouts

```
FISSION_LOCALS=true ./bin/rails s
```

This will use local paths instead of repos for fission
related gems. It assumes everything will be in the same
directory on the local machine. It requires all fission
used gems to be local. Look in the Gemfile to see the
full list.

### Enable github OAuth support

Use the hw-test for local testing:

```
GITHUB_KEY='KEY' GITHUB_SECRET='SECRET' bundle exec rails s
```

The key and secret and be found in the application section
on github: https://github.com/organizations/heavywater/settings/applications/69745
