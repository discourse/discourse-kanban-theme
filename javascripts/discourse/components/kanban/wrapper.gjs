import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import DButton from "discourse/components/d-button";
import DiscourseKanbanList from "./list";
import bodyClass from "discourse/helpers/body-class";
import i18n from "discourse-common/helpers/i18n";
import concatClass from "discourse/helpers/concat-class";
import KanbanOptionsModal from "./modal/options";
import { getOwner } from "@ember/application";

export default class Kanban extends Component {
  <template>
    {{#if this.kanbanManager.active}}
      <div
        class={{concatClass
          "discourse-kanban"
          (if this.kanbanManager.fullscreen "fullscreen" "inline")
        }}
      >
        {{#if this.kanbanManager.fullscreen}}
          <div class="fullscreen-close-wrapper">
            <DButton
              class="fullscreen-close"
              @icon="times"
              @action={{this.exitFullscreen}}
              title={{themePrefix "fullscreen"}}
            />
          </div>
        {{/if}}
        <div class="discourse-kanban-container">
          {{#each this.kanbanManager.listDefinitions as |definition|}}
            <DiscourseKanbanList
              @definition={{definition}}
              @dragData={{this.dragData}}
              @setDragDataUpstream={{this.setDragData}}
            />
          {{else}}
            <div class="discourse-kanban-list kanban-empty-state">
              {{i18n (themePrefix "no_lists")}}
              <DButton
                @icon="filter"
                class="btn-primary"
                @action={{this.openSettings}}
                @label={{themePrefix "configure"}}
              />
            </div>
          {{/each}}

          <div class="kanban-spacer"></div>
        </div>

        {{bodyClass "kanban-active"}}

        {{#if this.isLegacyTopicList}}
          {{bodyClass "kanban-legacy-topic-list"}}
        {{/if}}
      </div>
    {{/if}}
  </template>

  @service kanbanManager;
  @service modal;

  @tracked dragData;

  get isLegacyTopicList() {
    return !!getOwner(this).resolveRegistration("controller:discovery/topics") ;
  }

  @action
  setDragData(data) {
    this.dragData = data;
  }

  @action
  exitFullscreen() {
    this.kanbanManager.fullscreen = false;
  }

  @action
  openSettings(menu) {
    this.modal.show(KanbanOptionsModal);
    menu.close();
  }
}
