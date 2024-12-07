import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import DButton from "discourse/components/d-button";
import bodyClass from "discourse/helpers/body-class";
import concatClass from "discourse/helpers/concat-class";
import htmlClass from "discourse/helpers/html-class";
import i18n from "discourse-common/helpers/i18n";
import DiscourseKanbanList from "./list";
import KanbanOptionsModal from "./modal/options";

const onWindowResize = modifier((element, [callback]) => {
  const wrappedCallback = () => callback(element);
  window.addEventListener("resize", wrappedCallback);

  return () => {
    window.removeEventListener("resize", wrappedCallback);
  };
});

function calcOffset(element) {
  schedule("afterRender", () => {
    element.style.setProperty(
      "--kanban-offset-top",
      `${element.getBoundingClientRect().top}px`
    );
  });
}

export default class Kanban extends Component {
  @service kanbanManager;
  @service modal;

  @tracked dragData;

  @action
  setDragData(data) {
    this.dragData = data;
  }

  @action
  exitFullscreen() {
    this.kanbanManager.fullscreen = false;
    this.kanbanManager.calcListsHeights();
  }

  @action
  openSettings() {
    this.modal.show(KanbanOptionsModal);
  }

  <template>
    {{#if this.kanbanManager.active}}
      <div
        class={{concatClass
          "discourse-kanban"
          (if this.kanbanManager.fullscreen "kanban-fullscreen" "kanban-inline")
        }}
        {{onWindowResize calcOffset}}
        {{didInsert calcOffset}}
      >
        {{#if this.kanbanManager.fullscreen}}
          <div class="fullscreen-close-wrapper">
            <DButton
              class="fullscreen-close"
              @icon="xmark"
              @action={{this.exitFullscreen}}
              @title={{themePrefix "fullscreen"}}
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
        </div>

        {{htmlClass "kanban-active"}}
        {{bodyClass "kanban-active"}}
      </div>
    {{/if}}
  </template>
}
