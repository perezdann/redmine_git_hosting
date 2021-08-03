# frozen_string_literal: true

require_dependency 'member'

module RedmineGitHosting
  module Patches
    module MemberPatch
      include RedmineGitHosting::GitoliteAccessor::Methods

      def self.prepended(base)
        base.class_eval do
          after_commit :update_project
        end
      end

      private

      def update_project
        gitolite_accessor.update_projects [project.id],
                                          message: "Membership changes on project '#{project}', update!"
      end
    end
  end
end

Member.prepend RedmineGitHosting::Patches::MemberPatch unless Member.included_modules.include? RedmineGitHosting::Patches::MemberPatch
