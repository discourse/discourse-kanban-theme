# frozen_string_literal: true

require_relative "page_objects/pages/kanban_board"

RSpec.describe "Testing A Theme or Theme Component", system: true do
  def tagged_topic(*tags)
    topic = Fabricate(:topic, tags: tags)
    Fabricate(:post, topic: topic)
    topic
  end

  fab!(:modern_js) { Fabricate(:tag, name: "modern-js") }
  fab!(:chat) { Fabricate(:tag, name: "chat") }

  fab!(:active) { Fabricate(:tag, name: "active") }
  fab!(:backlog) { Fabricate(:tag, name: "backlog") }

  fab!(:modern_js_active) { tagged_topic(modern_js, active) }
  fab!(:chat_active) { tagged_topic(chat, active) }
  fab!(:modern_js_backlog) { tagged_topic(modern_js, backlog) }
  fab!(:chat_backlog) { tagged_topic(chat, backlog) }

  fab!(:user) { Fabricate(:admin, refresh_auto_groups: true) }

  let!(:theme) { upload_theme_component }

  before { sign_in user }

  it "should function without tag / category filters" do
    visit "/"

    expect(page).to have_css(".topic-list-item") # Fully loaded
    expect(page).not_to have_css("body.kanban-active")

    find(".kanban-nav").click

    expect(page).to have_css("body.kanban-active")
    expect(page).to have_css(".discourse-kanban-list", count: 1)
    expect(page).to have_css(".discourse-kanban-list .topic-card", count: 4)

    find(".kanban-controls").click
    find(".configure-kanban-button").click

    mode_chooser = PageObjects::Components::SelectKit.new(".kanban-mode-chooser")
    mode_chooser.expand
    mode_chooser.select_row_by_value("tags")
    mode_chooser.collapse

    tag_chooser = PageObjects::Components::SelectKit.new(".kanban-tag-chooser")
    tag_chooser.expand
    tag_chooser.select_row_by_name("active")
    tag_chooser.select_row_by_name("backlog")
    tag_chooser.collapse

    find(".kanban-modal .btn-primary").click

    expect(page).to have_css(".discourse-kanban-list", count: 2)
    lists = page.all(".discourse-kanban-list")
    active_list = lists[0]
    backlog_list = lists[1]

    expect(active_list.find(".list-title")).to have_text("#active")
    expect(backlog_list.find(".list-title")).to have_text("#backlog")

    expect(active_list).to have_css(".topic-card", count: 2)
    expect(backlog_list).to have_css(".topic-card", count: 2)

    card = active_list.find("[data-topic-id='#{chat_active.id}']")
    page.execute_script("arguments[0].scrollIntoView();", card)
    card.drag_to(backlog_list)
    find(".dialog-content .btn-primary").click

    expect(active_list).to have_css(".topic-card", count: 1)
    expect(backlog_list).to have_css(".topic-card", count: 3)
  end

  it "should function when filtered to tag" do
    visit "/"
    tag_drop = PageObjects::Components::SelectKit.new(".category-breadcrumb .tag-drop")
    tag_drop.select_row_by_name("chat")

    find(".kanban-nav").click

    visit "/tag/chat?board=tags:active,backlog"

    lists = page.all(".discourse-kanban-list")
    active_list = lists[0]
    backlog_list = lists[1]

    expect(active_list).to have_css(".topic-card", count: 1)
    expect(backlog_list).to have_css(".topic-card", count: 1)

    active_list.find("[data-topic-id='#{chat_active.id}']").drag_to(backlog_list)

    find(".dialog-content .btn-primary").click

    expect(active_list).not_to have_css(".topic-card")
    expect(backlog_list).to have_css(".topic-card", count: 2)
  end

  it "filters by discovery tag when using default board on tag page" do
    category = Fabricate(:category, name: "General")
    topic_with_tag = Fabricate(:topic, category: category, tags: [chat])
    Fabricate(:post, topic: topic_with_tag)
    topic_without_tag = Fabricate(:topic, category: category, tags: [modern_js])
    Fabricate(:post, topic: topic_without_tag)

    visit "/tag/chat?board=default"

    expect(page).to have_css(".discourse-kanban-list")
    general_list =
      page.all(".discourse-kanban-list").find { |l| l.find(".list-title").text == "General" }

    expect(general_list).to have_css(".topic-card", count: 1)
    expect(general_list).to have_css("[data-topic-id='#{topic_with_tag.id}']")
    expect(general_list).not_to have_css("[data-topic-id='#{topic_without_tag.id}']")
  end

  it "should function with auto-detected top tags (no explicit tag list)" do
    kanban_board = PageObjects::Pages::KanbanBoard.new

    visit "/latest?board=tags"

    expect(kanban_board).to have_list_with_title("#active")
    expect(kanban_board).to have_list_with_title("#backlog")
    expect(kanban_board).to have_list_with_title("#chat")
    expect(kanban_board).to have_list_with_title("#modern-js")
  end

  it "displays untagged topics in @untagged column" do
    untagged_topic = Fabricate(:topic, title: "Topic without any tags")
    Fabricate(:post, topic: untagged_topic)
    kanban_board = PageObjects::Pages::KanbanBoard.new

    visit "/latest?board=tags:active,@untagged"

    expect(kanban_board).to have_list_with_title("#active")
    expect(kanban_board).to have_list_with_title("Untagged")
    expect(kanban_board).to have_topics_in_list(
      "#active",
      count: 2,
      topics: [modern_js_active, chat_active],
    )
    expect(kanban_board).to have_topics_in_list("Untagged", count: 1, topics: [untagged_topic])
  end
end
