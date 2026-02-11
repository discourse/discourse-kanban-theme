# frozen_string_literal: true

module PageObjects
  module Pages
    class KanbanBoard < PageObjects::Pages::Base
      def visit_tag_page(tag)
        visit(tag_path(tag))
        self
      end

      def visit_tag_board(tag, descriptor: "default")
        visit("#{tag_path(tag)}?board=#{descriptor}")
        self
      end

      def click_nav
        find(".kanban-nav").click
        self
      end

      def active?
        page.has_css?("body.kanban-active")
      end

      def has_list_with_title?(title)
        page.has_css?(".discourse-kanban-list .list-title", text: title)
      end

      def has_topics_in_list?(title, count:, topics:)
        list = page.find(".discourse-kanban-list", text: title)
        return false unless list.has_css?(".topic-card", count: count)
        topics.all? { |topic| list.has_css?("[data-topic-id='#{topic.id}']") }
      end

      private

      # TODO: Once 2026.2.0 is released, add a .discourse-compatibility entry
      # and simplify to just use tag.url directly.
      def tag_path(tag)
        tag.respond_to?(:slug_for_url) ? tag.url : "/tag/#{tag.name}"
      end
    end
  end
end
