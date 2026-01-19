# frozen_string_literal: true

module PageObjects
  module Pages
    class KanbanBoard < PageObjects::Pages::Base
      def has_list_with_title?(title)
        page.has_css?(".discourse-kanban-list .list-title", text: title)
      end

      def has_topics_in_list?(title, count:, topics:)
        list = page.find(".discourse-kanban-list", text: title)
        return false unless list.has_css?(".topic-card", count: count)
        topics.all? { |topic| list.has_css?("[data-topic-id='#{topic.id}']") }
      end
    end
  end
end
