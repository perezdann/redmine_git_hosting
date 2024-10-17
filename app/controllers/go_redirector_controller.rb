# frozen_string_literal: true

class GoRedirectorController < ApplicationController
  protect_from_forgery with: :exception
  include XitoliteRepositoryFinder

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_action :check_if_login_required

  before_action :find_xitolite_repository_by_path

  def index; end
end
