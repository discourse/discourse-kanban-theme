import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import i18n from "discourse-common/helpers/i18n";

export default class KanbanNav extends Component {
  <template>
    <li>
      <a href={{this.href}} class={{if this.active "active"}}>
        {{i18n (themePrefix "menu_label")}}
      </a>
    </li>
  </template>

  @service kanbanHelper;

  get href() {
    const { category, tag } = this.args.outletArgs;
    return this.kanbanHelper.getBoardUrl({ category, tag });
  }

  get active() {
    const { filterMode } = this.args.outletArgs;
    return filterMode.split("/").pop() === "latest" && this.kanbanHelper.active;
  }
}
