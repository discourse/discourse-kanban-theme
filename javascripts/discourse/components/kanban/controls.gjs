import DButton from "discourse/components/d-button";
import CopyLinkButton from "./copy-link-button";
import DMenu from "float-kit/components/d-menu";
import Component from "@glimmer/component";
import KanbanOptionsModal from "./modal/options";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import bodyClass from "discourse/helpers/body-class";
import { fn } from "@ember/helper";
import i18n from "discourse-common/helpers/i18n";

export default class KanbanControls extends Component {
  <template>
    {{#if this.kanbanManager.active}}
      <DMenu
        class="kanban-controls"
        @icon="far-list-alt"
        @title={{i18n (themePrefix "controls")}}
        as |menu|
      >
        <ul class="kanban-controls">
          <li>
            <DButton
              @icon="filter"
              @action={{fn this.openSettings menu}}
              @label={{themePrefix "configure"}}
              class="configure-kanban-button btn-transparent"
            />
          </li>
          <li>
            <CopyLinkButton />
          </li>
          <li>
            <DButton
              @icon={{if
                this.kanbanManager.fullscreen
                "discourse-compress"
                "discourse-expand"
              }}
              class="btn-transparent"
              @action={{this.toggleFullscreen}}
              @label={{themePrefix "fullscreen"}}
            />
          </li>
        </ul>
      </DMenu>

      {{#if this.kanbanManager.fullscreen}}
        {{bodyClass "kanban-fullscreen"}}
      {{/if}}
    {{/if}}
  </template>

  @service modal;
  @service kanbanManager;

  @action
  toggleFullscreen() {
    this.kanbanManager.fullscreen = !this.kanbanManager.fullscreen;
  }

  @action
  openSettings(menu) {
    this.modal.show(KanbanOptionsModal);
    menu.close();
  }
}
