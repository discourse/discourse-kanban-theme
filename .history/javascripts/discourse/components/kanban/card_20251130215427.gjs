import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import PluginOutlet from "discourse/components/plugin-outlet";
import TopicStatus from "discourse/components/topic-status";
import categoryBadge from "discourse/helpers/category-badge";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import formatDate from "discourse/helpers/format-date";
import lazyHash from "discourse/helpers/lazy-hash";
import { renderAvatar } from "discourse/helpers/user-avatar";
import renderTag from "discourse/lib/render-tag";
import { modifier } from "ember-modifier";

const touchDrag = modifier((element, [component]) => {
  let longPressTimer = null;
  let isDragging = false;
  let startX = 0;
  let startY = 0;
  
  const handleTouchStart = (e) => {
    const touch = e.touches[0];
    startX = touch.clientX;
    startY = touch.clientY;
    
    longPressTimer = setTimeout(() => {
      isDragging = true;
      e.preventDefault(); // Now prevent defaults for dragging
      component.dragStart({ dataTransfer: { dropEffect: "move" }, stopPropagation: () => {}, preventDefault: () => {} });
      if (navigator.vibrate) navigator.vibrate(50);
    }, 500);
  };
  
  const handleTouchMove = (e) => {
    const touch = e.touches[0];
    const deltaX = Math.abs(touch.clientX - startX);
    const deltaY = Math.abs(touch.clientY - startY);
    
    // Cancel long press if finger moves too much before timer fires
    if (longPressTimer && (deltaX > 10 || deltaY > 10)) {
      clearTimeout(longPressTimer);
      longPressTimer = null;
    }
    
    // Only prevent default if we're actually dragging
    if (isDragging) {
      e.preventDefault();
    }
  };
  
  const handleTouchEnd = (e) => {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      longPressTimer = null;
    }
    
    if (isDragging) {
      e.preventDefault(); // Prevent navigation
      
      const touch = e.changedTouches[0];
      const targetElement = document.elementFromPoint(touch.clientX, touch.clientY);
      const listElement = targetElement?.closest('.discourse-kanban-list');
      
      if (listElement) {
        const dropEvent = new Event('drop', { bubbles: true });
        listElement.dispatchEvent(dropEvent);
      }
      
      component.dragEnd({ stopPropagation: () => {} });
      isDragging = false;
      if (navigator.vibrate) navigator.vibrate(30);
    }
  };
  
  const handleContextMenu = (e) => {
    // Prevent context menu always during touch interaction
    e.preventDefault();
  };
  
  element.addEventListener('touchstart', handleTouchStart, { passive: false });
  element.addEventListener('touchmove', handleTouchMove, { passive: false });
  element.addEventListener('touchend', handleTouchEnd, { passive: false });
  element.addEventListener('contextmenu', handleContextMenu);
  
  return () => {
    if (longPressTimer) clearTimeout(longPressTimer);
    element.removeEventListener('touchstart', handleTouchStart);
    element.removeEventListener('touchmove', handleTouchMove);
    element.removeEventListener('touchend', handleTouchEnd);
    element.removeEventListener('contextmenu', handleContextMenu);
  };
});

export default class KanbanCard extends Component {
  @service kanbanManager;

  @tracked dragging;

  @action
  dragStart(event) {
    this.dragging = true;
    this.args.setDragData({ topic: this.args.topic });
    if (event.dataTransfer) {
      event.dataTransfer.dropEffect = "move";
    }
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

  get showImage() {
    return settings.show_topic_thumbnail && this.imageUrl;
  }

  get imageUrl() {
    return this.args.topic.image_url;
  }

  get showCategory() {
    const definitionCategory = this.args.definition.params.category;
    const discoveryCategory = this.kanbanManager.discoveryCategory;
    return !(definitionCategory || discoveryCategory);
  }

  get showDetailed() {
    return this.cardStyle === "detailed";
  }

  get lastPoster() {
    return this.args.topic.posters.find((poster) =>
      poster.extras?.includes("latest")
    );
  }

  get cardActivityCssClass() {
    if (!settings.show_activity_indicators) {
      return "";
    }

    const bumpedAt = moment(this.args.topic.bumpedAt);
    if (bumpedAt < moment().add(-20, "days")) {
      return "card-stale";
    }
    if (bumpedAt < moment().add(-7, "days")) {
      return "card-no-recent-activity";
    }

    return "";
  }

  <template>
    <a
      class={{concatClass
        "topic-card"
        (if this.topic.unseen "topic-unseen")
        (if this.dragging "dragging")
        this.cardActivityCssClass
      }}
      draggable="true"
      href={{@topic.lastUnreadUrl}}
      data-topic-id={{@topic.id}}
      {{on "dragstart" this.dragStart}}
      {{on "dragend" this.dragEnd}}
      {{touchDrag this}}
    >
      <div class="card-row card-row__topic-details">
        <TopicStatus @topic={{@topic}} />
        <span class="topic-title">{{@topic.title}}</span>
        {{#unless this.showDetailed}}
          {{formatDate @topic.bumpedAt format="tiny" noTitle="true"}}
        {{/unless}}
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
            {{categoryBadge @topic.category}}
          </div>
        {{/if}}

        {{#unless this.showDetailed}}
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
              {{#each-in
                @topic.indirectly_assigned_to
                as |target_id assignment|
              }}

                {{! template-lint-disable no-nested-interactive }}
                <div class="assigned-to">
                  <a href="/t/{{@topic.id}}/{{assignment.post_number}}">
                    {{icon "user-plus"}}{{assignment.assigned_to.username}}
                  </a>
                </div>
              {{/each-in}}
            {{/if}}
          </div>
        {{/unless}}
      </div>

      {{#if this.showDetailed}}
        <div class="card-row card-row__user-details-row">
          <div class="last-post-by">
            {{formatDate @topic.bumpedAt format="tiny" noTitle="true"}}
            ({{this.lastPoster.user.username}})
          </div>

          <div class="topic-assignments-with-avatars">
            {{#if @topic.assigned_to_user.username}}
              {{htmlSafe
                (renderAvatar
                  @topic.assigned_to_user
                  avatarTemplatePath="avatar_template"
                  usernamePath="username"
                  namePath="name"
                  imageSize="tiny"
                )
              }}
            {{/if}}

            {{#if @topic.indirectly_assigned_to}}
              {{#each-in
                @topic.indirectly_assigned_to
                as |target_id assignment|
              }}

                {{htmlSafe
                  (renderAvatar
                    assignment.assigned_to
                    avatarTemplatePath="avatar_template"
                    usernamePath="username"
                    namePath="name"
                    imageSize="tiny"
                  )
                }}
              {{/each-in}}
            {{/if}}
          </div>
        </div>
      {{/if}}

      {{#if this.showImage}}
        <div class="card-row card-row__thumbnail-row">
          <img class="thumbnail" src={{this.imageUrl}} />
        </div>
      {{/if}}

      <PluginOutlet
        @name="kanban-card-bottom"
        @outletArgs={{lazyHash topic=@topic}}
      />
    </a>
  </template>
}
