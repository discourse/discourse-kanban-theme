import Component from "@glimmer/component";
import { service } from "@ember/service";
import DiscourseKanban from "../../components/kanban/wrapper";

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
