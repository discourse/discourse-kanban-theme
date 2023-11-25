import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import KanbanOptionsModal from "./modal/options";
import { tracked } from "@glimmer/tracking";
import DButton from "discourse/components/d-button";
import DiscourseKanbanList from "./list";
import CopyLinkButton from "./copy-link-button";
import bodyClass from "discourse/helpers/body-class";
import i18n from "discourse-common/helpers/i18n";

export default class Kanban extends Component {
  <template>
    {{#if this.kanbanManager.active}}
      <div class="discourse-kanban {{if this.fullscreen 'fullscreen'}}">
        <div class="discourse-kanban-container">
          <div class="kanban-spacer">
            <DButton
              @icon={{if
                this.fullscreen
                "discourse-compress"
                "discourse-expand"
              }}
              @action={{this.toggleFullscreen}}
              title={{themePrefix "fullscreen"}}
            />
            <DButton
              @icon="filter"
              @action={{this.openSettings}}
              title={{themePrefix "configure"}}
              class="configure-kanban-button"
            />
            <CopyLinkButton />
          </div>

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

        {{#if this.fullScreen}}
          {{bodyClass "kanban-fullscreen"}}
        {{/if}}
      </div>
    {{/if}}
  </template>

  @service kanbanManager;
  @service modal;

  @tracked fullscreen = false;
  @tracked dragData;

  @action
  setDragData(data) {
    this.dragData = data;
  }

  @action
  toggleFullscreen() {
    this.fullscreen = !this.fullscreen;
  }

  @action
  openSettings() {
    this.modal.show(KanbanOptionsModal);
  }
}
