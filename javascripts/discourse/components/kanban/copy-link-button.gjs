import Component from "@glimmer/component";
import DButton from "discourse/components/d-button";
import { action } from "@ember/object";
import discourseDebounce from "discourse-common/lib/debounce";
import { tracked } from "@glimmer/tracking";
import concatClass from "discourse/helpers/concat-class";

export default class KanbanCopyLinkButton extends Component {
  <template>
    <DButton
      @icon={{if this.copyConfirm "check" "copy"}}
      class={{concatClass 'btn-transparent'}}
      @action={{this.copy}}
      @label={{themePrefix "copy_link"}}
    />
  </template>

  @tracked copyConfirm = false;

  @action
  copy() {
    const text = document.location;
    navigator.clipboard.writeText(text);
    this.copyConfirm = true;
    discourseDebounce(this.resetCopyButton, 2000);
  }

  @action
  resetCopyButton() {
    this.copyConfirm = false;
  }
}
