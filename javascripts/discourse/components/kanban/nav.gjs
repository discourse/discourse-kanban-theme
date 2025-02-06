import Component from "@glimmer/component";
import { service } from "@ember/service";
import concatClass from "discourse/helpers/concat-class";
import { i18n } from "discourse-i18n";
import { displayConnector } from "../../lib/kanban-utilities";

export default class KanbanNav extends Component {
  @service kanbanManager;

  get href() {
    const { category, tag } = this.args.outletArgs;
    return this.kanbanManager.getBoardUrl({ category, tag });
  }

  get active() {
    const { filterMode } = this.args.outletArgs;
    return (
      filterMode.split("/").pop() === "latest" && this.kanbanManager.active
    );
  }

  <template>
    {{#if (displayConnector this.kanbanManager.discoveryCategory.slug)}}
      <li>
        <a
          href={{this.href}}
          class={{concatClass "kanban-nav" (if this.active "active")}}
        >
          {{i18n (themePrefix "menu_label")}}
        </a>
      </li>
    {{/if}}
  </template>
}
