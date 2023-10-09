# frozen_string_literal: true

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

  fab!(:user) { Fabricate(:admin) }

  let!(:theme) { upload_theme_component }

  before {     sign_in user }

  it "should function without tag / category filters" do
    visit "/"

    expect(page).to have_css(".topic-list-item") # Fully loaded
    expect(page).not_to have_css("body.kanban-active")

    find(".kanban-nav").click

    expect(page).to have_css("body.kanban-active")
    expect(page).to have_css(".discourse-kanban-list", count: 1)
    expect(page).to have_css(".discourse-kanban-list .topic-card", count: 4)

    find(".configure-kanban-button").click

    mode_chooser = PageObjects::Components::SelectKit.new(".kanban-mode-chooser")
    mode_chooser.expand
    mode_chooser.select_row_by_value("tags")

    mode_chooser = PageObjects::Components::SelectKit.new(".kanban-tag-chooser")
    mode_chooser.expand
    mode_chooser.select_row_by_value("active")
    mode_chooser.select_row_by_value("backlog")
    mode_chooser.collapse

    find(".kanban-modal .btn-primary").click

    expect(page).to have_css(".discourse-kanban-list", count: 2)
    lists = page.all(".discourse-kanban-list")
    active_list = lists[0]
    backlog_list = lists[1]

    expect(active_list.find(".list-title")).to have_text("#active")
    expect(backlog_list.find(".list-title")).to have_text("#backlog")

    expect(active_list).to have_css(".topic-card", count: 2)
    expect(backlog_list).to have_css(".topic-card", count: 2)

    active_list.find("[data-topic-id='#{chat_active.id}']").drag_to(backlog_list)

    find(".dialog-content .btn-primary").click

    expect(active_list).to have_css(".topic-card", count: 1)
    expect(backlog_list).to have_css(".topic-card", count: 3)
  end

  it "should function when filtered to tag" do
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
end
