import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import i18n from "discourse-common/helpers/i18n";
import concatClass from "discourse/helpers/concat-class";

export default class KanbanNav extends Component {
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
}
