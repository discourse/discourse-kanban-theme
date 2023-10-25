import Component from "@glimmer/component";
import i18n from "discourse-common/helpers/i18n";
import eq from "truth-helpers/helpers/eq";
import renderTag from "discourse/lib/render-tag";
import TopicStatus from "discourse/components/topic-status";
import { renderAvatar } from "discourse/helpers/user-avatar";
import { htmlSafe } from "@ember/template";
import icon from "discourse-common/helpers/d-icon";
import PluginOutlet from "discourse/components/plugin-outlet";
import { hash } from "@ember/helper";
import { getOwner } from "@ember/application";
import concatClass from "discourse/helpers/concat-class";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { inject as service } from "@ember/service";

export default class KanbanCard extends Component {
  <template>
    <a
      class={{concatClass
        "topic-card"
        (if this.topic.unseen "topic-unseen")
        (if this.dragging "dragging")
      }}
      draggable="true"
      href={{@topic.lastUnreadUrl}}
      data-topic-id={{@topic.id}}
      {{on "dragstart" this.dragStart}}
      {{on "dragend" this.dragEnd}}
    >
      <div class="card-row">
        <TopicStatus @topic={{@topic}} />
        <span class="topic-title">{{@topic.title}}</span>
        {{this.formatDate @topic.bumpedAt format="tiny" noTitle="true"}}
      </div>

      <div class="card-row">
        {{#if this.showTags}}
          <div class="tags">
            {{#each this.tags as |tag|}}
              {{htmlSafe tag}}
            {{/each}}
          </div>
        {{/if}}
      </div>

      <div class="card-row">
        {{#if this.showCategory}}
          <div class="category">
            {{this.categoryBadge @topic.category}}
          </div>
        {{/if}}

        <div class="topic-assignments">
          {{#if @topic.assigned_to_user.username}}
            {{! template-lint-disable no-nested-interactive }}
            <div class="assigned-to">
              <a href={{@topic.assignedToUserPath}}>
                {{icon "user-plus"}}{{@topic.assigned_to_user.username}}
              </a>
            </div>
          {{/if}}

          {{#if @topic.indirectly_assigned_to}}
              {{#each-in @topic.indirectly_assigned_to as |target_id assignment|}}
                {{! template-lint-disable no-nested-interactive }}
                <div class="assigned-to">
                  <a href="/t/{{@topic.id}}/{{assignment.post_number}}">
                    {{icon "user-plus"}}{{assignment.assigned_to.username}}
                  </a>
                </div>
              {{/each-in}}
          {{/if}}
        </div>
      </div>

      {{#if this.showLastPoster}}
        <div class="card-row">
          <div class="last-post-by">
              {{! template-lint-disable no-nested-interactive }}
              <a
                href={{this.lastPoster.user.path}}
                data-user-card={{this.lastPoster.user.username}}
                class={{this.lastPoster.extraClasses}}
              >

                {{i18n (themePrefix "last_post_by")}} {{this.lastPoster.user.username}}
                {{htmlSafe
                  (renderAvatar
                    this.lastPoster
                    avatarTemplatePath="user.avatar_template"
                    usernamePath="user.username"
                    namePath="user.name"
                    imageSize="tiny"
                  )
                }}

              </a>
          </div>

        </div>
      {{/if}}

      <PluginOutlet
        @name="kanban-card-bottom"
        @outletArgs={{hash topic=@topic}}
      />
    </a>
  </template>

  @service kanbanManager;

  @tracked dragging;

  // TODO - FIX THIS ONCE CORE EXPORTS IT PROPERLY
  formatDate = getOwner(this).resolveRegistration("helper:format-date");
  categoryBadge = getOwner(this).resolveRegistration("helper:category-badge");

  @action
  dragStart(event) {
    this.dragging = true;
    this.args.setDragData({ topic: this.args.topic });
    event.dataTransfer.dropEffect = "move";
    event.stopPropagation();
  }

  @action
  dragEnd(event) {
    this.dragging = false;
    event.stopPropagation();
  }

  get showTags() {
    return settings.show_tags && this.tags.length;
  }

  get cardStyle() {
    return settings.card_style;
  }

  get tags() {
    const definitionTags = this.args.definition.params.tags || [];
    const discoveryTag = this.kanbanManager.discoveryTag?.id;
    const listTags = [...definitionTags, discoveryTag];

    return this.args.topic.tags
      .reject((t) => listTags?.includes(t))
      .map((t) => renderTag(t));
  }

  get showCategory() {
    const definitionCategory = this.args.definition.params.category;
    const discoveryCategory = this.kanbanManager.discoveryCategory;
    return !(definitionCategory || discoveryCategory);
  }

  get showLastPoster() {
    return this.cardStyle === "detailed";
  }

  get lastPoster() {
    return this.args.topic.posters.find((poster) => poster.extras?.includes("latest"));
  }
}
