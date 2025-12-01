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
  let clone = null;
  let cloneX = 0;
  let cloneY = 0;
  let dropButton = null;
  let cancelButton = null;
  let animationFrameId = null;
  let scrollContainer = null;
  let clickBlocker = null;
  
  const handleTouchStart = (e) => {
    // Don't allow drag if user is not logged in
    if (!component.currentUser) {
      return;
    }
    
    // Don't allow picking up another card if ANY card is being dragged
    const existingClone = document.querySelector('.kanban-dragging-clone');
    if (existingClone) {
      e.preventDefault();
      return;
    }
    
    const touch = e.touches[0];
    startX = touch.clientX;
    startY = touch.clientY;
    
    // Only start long press if not already dragging
    if (!isDragging) {
      longPressTimer = setTimeout(() => {
        pickUpCard(touch);
      }, 500);
    }
  };
  
  const pickUpCard = (touch) => {
    isDragging = true;
    
    // Create visual clone at fixed position
    clone = element.cloneNode(true);
    clone.classList.add('kanban-dragging-clone');
    clone.style.position = 'fixed';
    clone.style.zIndex = '10000';
    clone.style.opacity = '0.8';
    clone.style.pointerEvents = 'none';
    clone.style.width = element.offsetWidth + 'px';
    clone.style.backgroundColor = 'rgba(255, 255, 255, 0.25)';
    clone.style.border = '2px solid rgba(255, 255, 255, 0.4)';
    clone.style.borderRadius = '4px';
    
    // Get the original card's position in viewport
    const rect = element.getBoundingClientRect();
    
    // Position clone directly above the original card (same horizontal position)
    cloneX = rect.left;
    cloneY = rect.top - clone.offsetHeight - 44; // Move up by clone height + space for buttons
    clone.style.left = cloneX + 'px';
    clone.style.top = cloneY + 'px';
    document.body.appendChild(clone);
    
    // Create drop button underneath the clone
    dropButton = document.createElement('button');
    dropButton.textContent = 'Drop Card';
    dropButton.style.position = 'fixed';
    dropButton.style.left = cloneX + 'px';
    dropButton.style.top = (cloneY + clone.offsetHeight + 4) + 'px';
    dropButton.style.width = element.offsetWidth + 'px';
    dropButton.style.zIndex = '10001';
    dropButton.style.padding = '6px';
    dropButton.style.fontSize = '14px';
    dropButton.style.fontWeight = 'bold';
    dropButton.style.color = '#ffffff';
    dropButton.style.backgroundColor = 'rgba(0, 0, 0, 0.8)';
    dropButton.style.border = 'none';
    dropButton.style.borderRadius = '4px';
    dropButton.style.boxShadow = '0 2px 8px rgba(0, 0, 0, 0.5)';
    dropButton.style.cursor = 'pointer';
    dropButton.onclick = (e) => {
      e.preventDefault();
      e.stopPropagation();
      dropCard();
    };
    document.body.appendChild(dropButton);
    
    // Create cancel button (X) at top right of clone
    cancelButton = document.createElement('button');
    cancelButton.textContent = '✕';
    cancelButton.style.position = 'fixed';
    cancelButton.style.left = (cloneX + element.offsetWidth - 30) + 'px';
    cancelButton.style.top = (cloneY + 4) + 'px';
    cancelButton.style.width = '26px';
    cancelButton.style.height = '26px';
    cancelButton.style.zIndex = '10002';
    cancelButton.style.padding = '0';
    cancelButton.style.fontSize = '18px';
    cancelButton.style.fontWeight = 'bold';
    cancelButton.style.color = '#ffffff';
    cancelButton.style.backgroundColor = 'rgba(255, 0, 0, 0.8)';
    cancelButton.style.border = 'none';
    cancelButton.style.borderRadius = '50%';
    cancelButton.style.boxShadow = '0 2px 8px rgba(0, 0, 0, 0.5)';
    cancelButton.style.cursor = 'pointer';
    cancelButton.style.lineHeight = '26px';
    cancelButton.style.textAlign = 'center';
    cancelButton.onclick = (e) => {
      e.preventDefault();
      e.stopPropagation();
      cancelDrag();
    };
    document.body.appendChild(cancelButton);
    
    // Create full-screen overlay that blocks clicks but not scrolling
    clickBlocker = document.createElement('div');
    clickBlocker.style.position = 'fixed';
    clickBlocker.style.top = '0';
    clickBlocker.style.left = '0';
    clickBlocker.style.width = '100vw';
    clickBlocker.style.height = '100vh';
    clickBlocker.style.zIndex = '9999'; // Below clone but above everything else
    clickBlocker.style.pointerEvents = 'none'; // Allow scrolling
    clickBlocker.style.cursor = 'grabbing';
    document.body.appendChild(clickBlocker);
    
    // Block clicks on all cards
    const allCards = document.querySelectorAll('.topic-card');
    allCards.forEach(card => {
      card.style.pointerEvents = 'none';
      card.dataset.dragBlocked = 'true';
    });
    
    // Find the scrolling container
    scrollContainer = element.closest('.discourse-kanban');
    
    // Start animation loop for position updates
    const trackPosition = () => {
      if (isDragging) {
        updateClonePosition();
        animationFrameId = requestAnimationFrame(trackPosition);
      }
    };
    animationFrameId = requestAnimationFrame(trackPosition);
    
    // Dim original card
    element.style.opacity = '0.3';
    
    // Trigger the native dragstart event
    const dragStartEvent = new DragEvent('dragstart', {
      bubbles: true,
      cancelable: true,
      dataTransfer: new DataTransfer()
    });
    element.dispatchEvent(dragStartEvent);
    
    if (navigator.vibrate) navigator.vibrate(50);
  };
  
  const cancelDrag = () => {
    if (!isDragging) return;
    
    // Cancel animation frame
    if (animationFrameId) {
      cancelAnimationFrame(animationFrameId);
      animationFrameId = null;
    }
    
    // Remove clone, buttons, and click blocker
    if (clone) {
      clone.remove();
      clone = null;
    }
    if (dropButton) {
      dropButton.remove();
      dropButton = null;
    }
    if (cancelButton) {
      cancelButton.remove();
      cancelButton = null;
    }
    if (clickBlocker) {
      clickBlocker.remove();
      clickBlocker = null;
    }
    
    // Restore pointer events on all cards
    const blockedCards = document.querySelectorAll('[data-drag-blocked="true"]');
    blockedCards.forEach(card => {
      card.style.pointerEvents = '';
      delete card.dataset.dragBlocked;
    });
    
    // Restore original card
    element.style.opacity = '';
    
    // Trigger dragend event without dropping
    const dragEndEvent = new DragEvent('dragend', {
      bubbles: true,
      cancelable: true
    });
    element.dispatchEvent(dragEndEvent);
    
    isDragging = false;
    if (navigator.vibrate) navigator.vibrate(20);
  };
  
  const dropCard = () => {
    if (!isDragging) return;
    
    // Cancel animation frame
    if (animationFrameId) {
      cancelAnimationFrame(animationFrameId);
      animationFrameId = null;
    }
    
    // Find what's under the clone's center position
    const centerX = cloneX + (clone.offsetWidth / 2);
    const centerY = cloneY + (clone.offsetHeight / 2);
    const targetElement = document.elementFromPoint(centerX, centerY);
    const listElement = targetElement?.closest('.discourse-kanban-list');
    
    // Remove clone, buttons, and click blocker
    if (clone) {
      clone.remove();
      clone = null;
    }
    if (dropButton) {
      dropButton.remove();
      dropButton = null;
    }
    if (cancelButton) {
      cancelButton.remove();
      cancelButton = null;
    }
    if (clickBlocker) {
      clickBlocker.remove();
      clickBlocker = null;
    }
    
    // Restore pointer events on all cards
    const blockedCards = document.querySelectorAll('[data-drag-blocked="true"]');
    blockedCards.forEach(card => {
      card.style.pointerEvents = '';
      delete card.dataset.dragBlocked;
    });
    
    // Restore original card
    element.style.opacity = '';
    
    if (listElement) {
      const dropEvent = new DragEvent('drop', {
        bubbles: true,
        cancelable: true
      });
      listElement.dispatchEvent(dropEvent);
    }
    
    // Trigger dragend event
    const dragEndEvent = new DragEvent('dragend', {
      bubbles: true,
      cancelable: true
    });
    element.dispatchEvent(dragEndEvent);
    
    isDragging = false;
    if (navigator.vibrate) navigator.vibrate(30);
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
    
    // Allow free scrolling whether dragging or not
  };
  
  const updateClonePosition = () => {
    if (!clone || !scrollContainer) return;
    
    // Get the Kanban container boundaries in viewport
    const containerRect = scrollContainer.getBoundingClientRect();
    const cloneWidth = clone.offsetWidth;
    const cloneHeight = clone.offsetHeight;
    
    // Card stays locked to its initial viewport position
    // But constrain it to stay within the visible Kanban container
    let finalX = cloneX;
    let finalY = cloneY;
    
    // Keep card within horizontal bounds of container
    if (finalX < containerRect.left) {
      finalX = containerRect.left;
    } else if (finalX + cloneWidth > containerRect.right) {
      finalX = containerRect.right - cloneWidth;
    }
    
    // Keep card within vertical bounds of container  
    if (finalY < containerRect.top) {
      finalY = containerRect.top;
    } else if (finalY + cloneHeight + 44 > containerRect.bottom) {
      finalY = containerRect.bottom - cloneHeight - 44;
    }
    
    // Update positions
    clone.style.left = finalX + 'px';
    clone.style.top = finalY + 'px';
    
    if (dropButton) {
      dropButton.style.left = finalX + 'px';
      dropButton.style.top = (finalY + cloneHeight + 4) + 'px';
    }
    
    if (cancelButton) {
      cancelButton.style.left = (finalX + cloneWidth - 30) + 'px';
      cancelButton.style.top = (finalY + 4) + 'px';
    }
  };
  
  const handleTouchEnd = (e) => {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      longPressTimer = null;
    }
    
    // Don't drop on touch end - wait for drop button click
  };
  
  const handleContextMenu = (e) => {
    // Prevent context menu always during touch interaction
    e.preventDefault();
  };
  
  element.addEventListener('touchstart', handleTouchStart, { passive: false });
  element.addEventListener('touchmove', handleTouchMove, { passive: false });
  element.addEventListener('touchend', handleTouchEnd, { passive: false });
  element.addEventListener('contextmenu', handleContextMenu);
  
  // Scroll to show first column on initial load
  const container = element.closest('.discourse-kanban');
  if (container && container.scrollLeft === 0) {
    // Check if we're at the very start (in the invisible spacer)
    const firstList = container.querySelector('.discourse-kanban-list:first-child');
    if (firstList) {
      setTimeout(() => {
        firstList.scrollIntoView({ inline: 'start', block: 'nearest', behavior: 'auto' });
      }, 100);
    }
  }
  
  return () => {
    if (longPressTimer) clearTimeout(longPressTimer);
    if (animationFrameId) cancelAnimationFrame(animationFrameId);
    // Cancel any active drag on cleanup (e.g., navigation)
    if (isDragging) {
      cancelDrag();
    }
    element.removeEventListener('touchstart', handleTouchStart);
    element.removeEventListener('touchmove', handleTouchMove);
    element.removeEventListener('touchend', handleTouchEnd);
    element.removeEventListener('contextmenu', handleContextMenu);
  };
});

export default class KanbanCard extends Component {
  @service kanbanManager;
  @service currentUser;

  @tracked dragging;

  @action
  dragStart(event) {
    // Don't allow drag if user is not logged in
    if (!this.currentUser) {
      event.preventDefault();
      return;
    }
    
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
