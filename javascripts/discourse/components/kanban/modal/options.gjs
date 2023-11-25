import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import DiscourseURL from "discourse/lib/url";
import { equal } from "@ember/object/computed";
import { action } from "@ember/object";
import DModal from "discourse/components/d-modal";
import ComboBox from "select-kit/components/combo-box";
import TagChooser from "select-kit/components/tag-chooser";
import MultiSelect from "select-kit/components/multi-select";
import EmailGroupUserChooser from "select-kit/components/email-group-user-chooser";
import i18n from "discourse-common/helpers/i18n";
import { fn, hash } from "@ember/helper";
import DButton from "discourse/components/d-button";
import { tracked } from "@glimmer/tracking";

export default class KanbanOptionsController extends Component {
  <template>
    <DModal
      class="kanban-modal"
      @title={{i18n (themePrefix "modal.title")}}
      @closeModal={{@closeModal}}
    >
      <:body>
        <div class="control-group">
          <label>{{i18n (themePrefix "modal.mode")}}</label>
          <ComboBox
            @content={{this.modes}}
            @value={{this.mode}}
            @onChange={{fn (mut this.mode)}}
            @valueProperty="id"
            @nameProperty="id"
            @class="kanban-mode-chooser"
          />
        </div>

        <div class="control-group">
          <label>{{i18n (themePrefix "modal.lists")}}</label>
          {{#if this.isTags}}
            <TagChooser
              @tags={{this.tags}}
              @allowCreate={{false}}
              @filterPlaceholder={{i18n (themePrefix "modal.tags_placeholder")}}
              @everyTag={{true}}
              @class="kanban-tag-chooser"
            />
          {{else if this.isCategories}}
            <MultiSelect
              @content={{this.site.categories}}
              @value={{this.categories}}
              @filterPlaceholder={{i18n
                (themePrefix "modal.categories_placeholder")
              }}
            />
          {{else if this.isAssigned}}
            <EmailGroupUserChooser
              @value={{this.usernames}}
              @onChange={{fn (mut this.usernames)}}
              @options={{hash
                fullWidthWrap=true
                filterPlaceholder=(themePrefix "modal.usernames_placeholder")
              }}
            />
          {{/if}}
        </div>
      </:body>
      <:footer>
        <DButton
          class="btn-primary"
          @action={{this.apply}}
          @label={{themePrefix "modal.apply"}}
        />
      </:footer>
    </DModal>
  </template>

  @service kanbanManager;
  @service site;

  @tracked tags = [];
  @tracked usernames = [];
  @tracked categories = [];
  @tracked mode = "tags";
  modes = [{ id: "tags" }, { id: "categories" }, { id: "assigned" }];

  @equal("mode", "tags") isTags;
  @equal("mode", "categories") isCategories;
  @equal("mode", "assigned") isAssigned;

  constructor() {
    super(...arguments);
    const [mode, params] = this.kanbanManager.resolvedDescriptorParts;

    this.mode = mode;
    if (this.mode === "tags") {
      this.tags = params?.split(",") || [];
    } else if (this.mode === "categories") {
      this.categories = params?.split(",").map((v) => parseInt(v, 10)) || [];
    } else if (this.mode === "assigned") {
      this.usernames = params?.split(",") || [];
    }
  }

  @action
  apply() {
    let descriptor = "";
    if (this.isTags) {
      descriptor += "tags";
      if (this.tags.length > 0) {
        descriptor += `:${this.tags.join(",")}`;
      }
    } else if (this.isCategories) {
      descriptor += "categories";
      if (this.categories.length > 0) {
        descriptor += `:${this.categories.join(",")}`;
      }
    } else if (this.isAssigned) {
      descriptor += "assigned";
      if (this.usernames.length > 0) {
        descriptor += `:${this.usernames}`;
      }
    }

    let href = this.kanbanManager.getBoardUrl({
      category: this.kanbanManager.discoveryCategory,
      tag: this.kanbanManager.discoveryTag,
      descriptor,
    });

    this.args.closeModal();
    DiscourseURL.routeTo(href, { replaceURL: true });
  }
}
