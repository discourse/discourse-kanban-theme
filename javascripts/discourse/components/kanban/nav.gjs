import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import concatClass from "discourse/helpers/concat-class";
import i18n from "discourse-common/helpers/i18n";

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
    <li>
      <a
        href={{this.href}}
        class={{concatClass "kanban-nav" (if this.active "active")}}
      >
        {{i18n (themePrefix "menu_label")}}
      </a>
    </li>
  </template>
}
