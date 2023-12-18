import DiscourseKanban from "../../components/kanban/wrapper";
import Component from "@glimmer/component";
import { inject as service } from "@ember/service";

export default class KanbanBoard extends Component {
  @service kanbanManager;

  <template>
    {{#if this.kanbanManager.active}}
      <DiscourseKanban />
    {{else}}
      {{yield}}
    {{/if}}
  </template>
}
