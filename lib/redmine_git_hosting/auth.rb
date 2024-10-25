# frozen_string_literal: true

module RedmineGitHosting
  class Auth
    def find(login, password)
      user = User.find_by login: login
      # Return if user not found
      return if user.nil?
      
      # Return if user is locked
      return if user.locked?

      # Return if user is locked
      return if user.locked?

      # Return user if password matches
      user if user.check_password? password
    end
  end
end
