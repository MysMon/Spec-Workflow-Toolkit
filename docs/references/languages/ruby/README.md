
# Ruby Development

Comprehensive patterns and practices for Ruby development.

## Project Setup

### Ruby Project Structure

```
my-project/
├── app/                    # Rails: Application code
│   ├── controllers/
│   ├── models/
│   ├── services/
│   ├── jobs/
│   └── views/
├── config/
│   ├── application.rb
│   ├── database.yml
│   └── routes.rb
├── db/
│   ├── migrate/
│   └── schema.rb
├── lib/
├── spec/                   # RSpec tests
│   ├── models/
│   ├── requests/
│   └── support/
├── Gemfile
├── Gemfile.lock
├── .rubocop.yml
└── .ruby-version
```

### Gemfile Example

```ruby
source 'https://rubygems.org'

ruby '3.3.0'

gem 'rails', '~> 7.1'
gem 'pg'
gem 'puma'
gem 'redis'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :test do
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
end
```

## Modern Ruby Patterns

### Data Classes (Ruby 3.2+)

```ruby
# Immutable value objects with Data class
User = Data.define(:id, :email, :name) do
  def display_name
    name.presence || email.split('@').first
  end
end

user = User.new(id: 1, email: 'john@example.com', name: 'John')
user.email # => 'john@example.com'
```

### Pattern Matching

```ruby
def process_response(response)
  case response
  in { status: 200..299, body: }
    { success: true, data: body }
  in { status: 400..499, error: message }
    { success: false, error: message }
  in { status: 500.. }
    { success: false, error: 'Server error' }
  end
end

# Array pattern matching
case [1, 2, 3]
in [first, *rest]
  puts "First: #{first}, Rest: #{rest}"
end
```

### Result Pattern

```ruby
# Using dry-monads or custom implementation
class Result
  attr_reader :value, :error

  def self.success(value)
    new(value: value, success: true)
  end

  def self.failure(error)
    new(error: error, success: false)
  end

  def initialize(value: nil, error: nil, success:)
    @value = value
    @error = error
    @success = success
  end

  def success? = @success
  def failure? = !@success

  def and_then(&block)
    return self if failure?
    block.call(value)
  end
end

# Usage in service
class CreateUser
  def call(params)
    validate(params)
      .and_then { |valid| persist(valid) }
      .and_then { |user| send_welcome_email(user) }
  end
end
```

## Code Style

### Naming Conventions

```ruby
# Classes and modules: PascalCase
class UserRepository
end

module Authentication
end

# Methods and variables: snake_case
def find_user_by_id(user_id)
  current_user = User.find(user_id)
end

# Constants: SCREAMING_SNAKE_CASE
MAX_RETRIES = 3
API_BASE_URL = 'https://api.example.com'

# Predicates: end with ?
def valid?
  errors.empty?
end

# Dangerous methods: end with !
def save!
  raise InvalidRecord unless save
end

# Private methods: no prefix needed
private

def internal_helper
end
```

### Idiomatic Ruby

```ruby
# Use guard clauses
def process(user)
  return Result.failure(:not_found) if user.nil?
  return Result.failure(:inactive) unless user.active?

  do_processing(user)
end

# Use symbols for hash keys
user = { name: 'John', email: 'john@example.com' }

# Use string interpolation
message = "Hello, #{user[:name]}!"

# Use blocks
users.each do |user|
  process(user)
end

# Use safe navigation
user&.profile&.avatar_url

# Use keyword arguments
def create_user(name:, email:, role: :member)
end

# Use frozen string literal
# frozen_string_literal: true
```

## Error Handling

### Custom Exceptions

```ruby
module Errors
  class BaseError < StandardError
    attr_reader :code, :context

    def initialize(message, code:, context: {})
      @code = code
      @context = context
      super(message)
    end
  end

  class NotFoundError < BaseError
    def initialize(resource, id)
      super(
        "#{resource} not found",
        code: :not_found,
        context: { resource: resource, id: id }
      )
    end
  end

  class ValidationError < BaseError
    def initialize(errors)
      super(
        'Validation failed',
        code: :validation_error,
        context: { errors: errors }
      )
    end
  end
end
```

## Testing

### RSpec Example

```ruby
# spec/services/user_service_spec.rb
require 'rails_helper'

RSpec.describe UserService do
  describe '#find_by_id' do
    subject(:service) { described_class.new(repository: repository) }

    let(:repository) { instance_double(UserRepository) }
    let(:user) { build(:user, id: 1, name: 'John') }

    context 'when user exists' do
      before do
        allow(repository).to receive(:find).with(1).and_return(user)
      end

      it 'returns the user' do
        result = service.find_by_id(1)

        expect(result).to be_success
        expect(result.value.name).to eq('John')
      end
    end

    context 'when user does not exist' do
      before do
        allow(repository).to receive(:find).with(999).and_return(nil)
      end

      it 'returns failure' do
        result = service.find_by_id(999)

        expect(result).to be_failure
        expect(result.error).to eq(:not_found)
      end
    end
  end
end
```

### FactoryBot

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    role { :member }

    trait :admin do
      role { :admin }
    end

    trait :with_posts do
      after(:create) do |user|
        create_list(:post, 3, user: user)
      end
    end
  end
end
```

## Common Commands

```bash
# Bundler
bundle install
bundle update
bundle add gem_name
bundle exec rails s

# Rails
rails new myapp --api --database=postgresql
rails generate model User name:string email:string
rails generate controller Users index show
rails db:migrate
rails db:seed
rails console
rails routes

# RSpec
bundle exec rspec
bundle exec rspec spec/models/
bundle exec rspec --format documentation
bundle exec rspec --only-failures

# RuboCop
bundle exec rubocop
bundle exec rubocop -a  # Auto-correct
bundle exec rubocop -A  # Aggressive auto-correct

# IRB
irb
bundle exec rails console

# Rake
bundle exec rake -T
bundle exec rake db:migrate
```

## Package Managers

| Task | Bundler |
|------|---------|
| Install | `bundle install` |
| Add gem | `bundle add gem_name` |
| Update | `bundle update` |
| Update gem | `bundle update gem_name` |
| Remove | Remove from Gemfile, run `bundle install` |

## Framework-Specific Patterns

For framework-specific guidance, see:
- [Rails patterns](RAILS.md)
- [Sinatra patterns](SINATRA.md)
- [Hanami patterns](HANAMI.md)

## Rules

- ALWAYS use frozen_string_literal pragma
- ALWAYS use keyword arguments for 3+ parameters
- NEVER use global variables
- ALWAYS prefer composition over inheritance
- NEVER rescue Exception (use StandardError)
- ALWAYS use dependency injection
- NEVER use `eval` or `class_eval` without need
- ALWAYS validate input at boundaries
- NEVER store secrets in code
- ALWAYS use strong parameters in Rails
