import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Topic from "discourse/models/topic";
import I18n from "I18n";
import { action } from "@ember/object";
import icon from "discourse-common/helpers/d-icon";
import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import DiscourseKanbanCard from "./card";
import i18n from "discourse-common/helpers/i18n";
import { on } from "@ember/modifier";
import { tracked } from "@glimmer/tracking";
import concatClass from "discourse/helpers/concat-class";
import { modifier } from "ember-modifier";

function removedElements(before, after) {
  if (!before) {
    return [];
  }

  if (!after) {
    return before;
  }

  return before.filter((x) => !after.includes(x));
}

function addedElements(before, after) {
  return removedElements(after, before);
}

const onIntersection = modifier((element, [callback]) => {
  const io = new IntersectionObserver((entries) => {
    if (entries[0].isIntersecting) {
      callback();
    }
  });

  io.observe(element);

  return () => {
    io.disconnect();
  };
});

export default class KanbanList extends Component {
  <template>
    {{! template-lint-disable modifier-name-case }}
    <div
      class={{concatClass
        "discourse-kanban-list"
        (if this.acceptDrag "accept-drag")
      }}
      {{on "dragover" this.dragOver}}
      {{on "dragleave" this.dragLeave}}
      {{on "drop" this.drop}}
    >
      <div class="list-title">
        {{#if @definition.icon}}{{icon @definition.icon}}{{/if}}
        {{this.renderedTitle}}
      </div>

      <div class="topics">
        <ConditionalLoadingSpinner @condition={{this.loading}}>
          {{#each this.list.topics as |topic|}}
            <DiscourseKanbanCard
              @topic={{topic}}
              @setDragData={{this.setDragData}}
              @definition={{@definition}}
            />
          {{else}}
            <div class="no_topics">
              {{i18n (themePrefix "no_topics")}}
            </div>
          {{/each}}

          <ConditionalLoadingSpinner @condition={{this.loadingMode}} />
        </ConditionalLoadingSpinner>

        <div class="list-bottom" {{onIntersection this.loadMore}}></div>
      </div>
    </div>
  </template>

  @service kanbanManager;
  @service dialog;
  @service modal;
  @service store;

  @tracked acceptDrag;
  @tracked loading = false;
  @tracked loadingMore = false;
  @tracked list;

  get renderedTitle() {
    return this.args.definition.title;
  }

  @action
  loadTopics() {
    this.loading = true;
    this.refreshTopics();
  }

  async refreshTopics() {
    if (!this.loading && !this.list) {
      return;
    }
    const defaultParams = {
      match_all_tags: true,
    };

    const { discoveryTag, discoveryCategory, discoveryParams } =
      this.kanbanManager;

    if (discoveryCategory) {
      defaultParams.category = discoveryCategory.id;
    }

    const params = {
      ...defaultParams,
      ...discoveryParams,
      ...this.args.definition.params,
    };

    if (discoveryTag) {
      params.tags = [...(params.tags || [])];
      params.tags.push(discoveryTag.id);
    }

    try {
      this.list = await this.store.findFiltered("topicList", {
        filter: "latest",
        params,
      });
    } finally {
      this.loading = false;
    }
  }

  @action
  dragLeave(event) {
    event.preventDefault();
    this.acceptDrag = false;
  }

  @action
  dragOver(event) {
    event.preventDefault();
    this.acceptDrag = true;
  }

  @action
  drop() {
    this.dropped();
    this.acceptDrag = false;
  }

  @action
  async loadMore() {
    if (!this.list && !this.loading) {
      return this.loadTopics(); // Initial load
    }

    if (this.loading || !this.list.canLoadMore || this.loadingMore) {
      return;
    }

    this.loadingMore = true;
    await this.list.loadMore();
    this.loadingMode = false;
  }

  @action
  dropped() {
    const { topic, oldDefinition, oldRefresh } = this.args.dragData;
    const thisDefinition = this.args.definition;

    let doUpdate = () => {};
    let requireConfirmation = settings.require_confirmation;
    let confirmationMessage = "";

    if (this.kanbanManager.mode === "tags") {
      const toAdd = addedElements(
        oldDefinition.params.tags,
        thisDefinition.params.tags
      );
      const toRemove = removedElements(
        oldDefinition.params.tags,
        thisDefinition.params.tags
      );
      doUpdate = () => {
        const existingTags = topic.tags;
        let newTags = existingTags.reject((t) =>
          toRemove
            .map((remove) => remove.toLowerCase())
            .includes(t.toLowerCase())
        );
        newTags.push(...toAdd);
        return Topic.update(topic, { tags: newTags, noBump: true })
          .then(() => {
            this.refreshTopics();
            oldRefresh();
          })
          .catch(popupAjaxError);
      };
      confirmationMessage = I18n.t(themePrefix("confirm_change_tags"), {
        remove: toRemove,
        add: toAdd,
        title: topic.title,
      });
    } else if (
      oldDefinition.params.assigned &&
      thisDefinition.params.assigned
    ) {
      let newUsername = thisDefinition.params.assigned;
      if (newUsername === "*" || newUsername === "nobody") {
        newUsername = undefined;
      }
      doUpdate = () => {
        const AssignModal =
          require("discourse/plugins/discourse-assign/discourse/components/modal/assign-user").default;
        this.modal.show(AssignModal, {
          model: {
            target: topic,
            username: newUsername,
            targetType: "Topic",
            onSuccess: () => {
              this.refreshTopics();
              oldRefresh();
            },
          },
        });
      };
      requireConfirmation = false;
    } else if (
      thisDefinition.params.status === "closed" &&
      oldDefinition.params.status === "open"
    ) {
      doUpdate = () => {
        topic.saveStatus("closed", true).then(() => {
          this.refreshTopics();
          oldRefresh();
        });
      };
      confirmationMessage = I18n.t(themePrefix("confirm_close"), {
        title: topic.title,
      });
    } else if (
      thisDefinition.params.status === "open" &&
      oldDefinition.params.status === "closed"
    ) {
      doUpdate = () => {
        topic.saveStatus("closed", false).then(() => {
          this.refreshTopics();
          oldRefresh();
        });
      };
      confirmationMessage = I18n.t(themePrefix("confirm_open"), {
        title: topic.title,
      });
    } else if (
      thisDefinition.params.category &&
      oldDefinition.params.category &&
      thisDefinition.params.category !== oldDefinition.params.category
    ) {
      doUpdate = () => {
        Topic.update(topic, {
          category_id: thisDefinition.params.category,
          noBump: true,
        })
          .then(() => {
            this.refreshTopics();
            oldRefresh();
          })
          .catch(popupAjaxError);
      };
      confirmationMessage = I18n.t(themePrefix("confirm_change_category"), {
        title: topic.title,
      });
    }

    if (requireConfirmation && confirmationMessage) {
      this.dialog.yesNoConfirm({
        message: confirmationMessage,
        didConfirm: doUpdate,
      });
    } else {
      doUpdate();
    }
  }

  @action
  setDragData(data) {
    data.oldDefinition = this.args.definition;
    data.oldRefresh = () => this.refreshTopics();
    this.args.setDragDataUpstream(data);
  }
}
