# ConstructionGuard

Welcome to Construction Guard!
It was written for the purpose of protecting the unpublished sites from the unauthorized users.

## Installation

Install the gem by adding the following to the application's Gemfile:

    gem 'construction_guard', git: 'https://github.com/Sanish777/construction_guard'

Install the gem by executing following command:

    $ bundle install

## Usage

### 1. Application Setup
Add the route for the construction guard in the routes file.

NOTE: the redirect url must be the '/constructionguard/github/callback'
```ruby
# config/routes.rb

get '/constructionguard/github/callback', to: 'construction_guard#github'

```
Create construction_guard_controller.rb file and add the following method to it.

```ruby
# app/controllers/construction_guard.rb

class ConstructionGuard < ApplicationController
	def github
		code = params[:code]
		ConstructionGuard::Middleware.setup_omniauth(request.env, response, code)
		redirect_to root_path
	end
end
```

Create construction_guard.rb inside the initializers directory.
You can configure the `under_construction` flag and `maintenance_message` in this file.
```ruby
# config/initializers/construction_guard.rb

require 'construction_guard/middleware'

Rails.application.config.middleware.use ConstructionGuard::Middleware, under_construction: true, maintenance_message: "This Site is currently Under Construction"
```

### ENV Configuration
```env
CLIENT_ID="Your Client ID"
CLIENT_SECRET="Your Client Secret"
TOP_SECRET_KEY="Your Secret Key"
ORGANIZATION_NAME="Your Organization Name"
```

NOTE: `TOP_SECRET_KEY` can be random set of string.

### OAUTH APP SETUP
1. [Create a OAuth App](https://github.com/settings/applications/new) from the developers Settings.
2. Add the required Application Information.
3. Authorization callback URL must be `{url}/constructionguard/github/callback`
4. Leave the `Enable Device Flow` unchecked.
5. You will get the `Client ID` and `Client Secrets` after successful creation.

### 3. Organization Setup

1. The user must [create an organization](https://github.com/account/organizations/new?plan=free&ref_cta=Create%2520a%2520free%2520organization&ref_loc=cards&ref_page=%2Forganizations%2Fplan) on the github.
2. Add the members to the organizations with the github usernames or emails.
3. After the creating the organizations, we must verify whether the members are private or public.
3. The members must be public for successful user authentication.
