# frozen_string_literal: true

Deface::Override.new virtual_path: 'repositories/show',
                     name: 'show-repositories-hook-bottom',
                     insert_before: 'erb[silent]:contains("other_formats_links")',
#                     original: 'f302d110cd10675a0a952f5f3e1ecfe57ebd38be',
                     original: '6032aa4d05ecf494ea6092b78c6bec9868c8fb70',
                     text: '<%= call_hook(:view_repositories_show_bottom, repository: @repository) %>'

Deface::Override.new virtual_path: 'repositories/show',
                     name: 'show-repositories-hook-sidebar',
                     insert_before: 'erb[silent]:contains("html_title")',
#                     original: '2a0a09659d76066b896016c72527d479c69463ec',
                     original: '6ae96d2f04bc498023cdb4dfbe8bd3c4b1c86f54',
                     partial: 'hooks/show_repositories_sidebar'

module Repositories
  module Show
  end
end
