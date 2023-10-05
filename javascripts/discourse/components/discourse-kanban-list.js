import Component from "@ember/component";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Topic from "discourse/models/topic";
import I18n from "I18n";
import { action } from "@ember/object";

export default class KanbanList extends Component {
  @service kanbanHelper;
  @service dialog;
  @service modal;

  tagName = "div";
  classNames = ["discourse-kanban-list"];
  classNameBindings = ["acceptDrag"];

  @discourseComputed("definition.title")
  renderedTitle(title) {
    return title;
  }

  loadTopics() {
    this.set("loading", true);

    this.refreshTopics();
  }

  refreshTopics() {
    if (!this.loading && !this.list) {
      return;
    }
    const defaultParams = {};
    if (this.kanbanHelper.discoveryCategory) {
      defaultParams.category = this.kanbanHelper.discoveryCategory.id;
    }

    const params = Object.assign(
      {},
      defaultParams,
      this.kanbanHelper.discoveryParams,
      this.definition.params
    );

    this.store
      .findFiltered("topicList", { filter: "latest", params })
      .then((list) => {
        this.set("list", list);
        this.set("loading", false);
      });
  }

  didInsertElement() {
    this._setupIntersectionObserver();
    super.didInsertElement();
  }

  _setupIntersectionObserver() {
    this.io = new IntersectionObserver((entries) => {
      if (entries[0].intersectionRatio <= 0) {
        return;
      }
      this.loadMore();
    });

    this.io.observe(this.element.querySelector(".list-bottom"));
  }

  willDestroyElement() {
    this.io.disconnect();
    super.willDestroyElement();
  }

  dragLeave(event) {
    event.preventDefault();
    this.set("acceptDrag", false);
  }

  dragOver(event) {
    event.preventDefault();
    this.set("acceptDrag", true);
  }

  drop() {
    this.dropped();
    this.set("acceptDrag", false);
  }

  @action
  loadMore() {
    if (!this.list && !this.loading) {
      return this.loadTopics(); // Initial load
    }

    if (this.loading || !this.list.canLoadMore || this.loadingMore) {
      return;
    }

    this.set("loadingMore", true);
    this.list.loadMore().then(() => this.set("loadingMore", false));
  }

  @action
  dropped() {
    const { topic, oldDefinition, oldRefresh } = this.dragData;

    let doUpdate = () => {};
    let requireConfirmation = settings.require_confirmation;
    let confirmationMessage = "";

    if (
      (oldDefinition.params.tags || oldDefinition.params.no_tags) &&
      this.definition.params.tags &&
      oldDefinition.params.tags !== this.definition.params.tags
    ) {
      doUpdate = () => {
        const existingTags = topic.tags;
        let newTags = existingTags.filter(
          (t) => t.toLowerCase() !== oldDefinition.params.tags.toLowerCase()
        );
        newTags.push(this.definition.params.tags);
        return Topic.update(topic, { tags: newTags, noBump: true })
          .then(() => {
            this.refreshTopics();
            oldRefresh();
          })
          .catch(popupAjaxError);
      };
      confirmationMessage = I18n.t(themePrefix("confirm_change_tags"), {
        remove: oldDefinition.params.tags,
        add: this.definition.params.tags,
        title: topic.title,
      });
    } else if (
      oldDefinition.params.assigned &&
      this.definition.params.assigned
    ) {
      let newUsername = this.definition.params.assigned;
      if (newUsername === "*" || newUsername === "nobody") {
        newUsername = undefined;
      }
      doUpdate = () => {
        // TODO FIXUP
        // return showModal("assign-user", {
        //   model: {
        //     topic,
        //     username: newUsername,
        //     onSuccess: () => {
        //       this.refreshTopics();
        //       oldRefresh();
        //     },
        //   },
        // });
      };
      requireConfirmation = false;
    } else if (
      this.definition.params.status === "closed" &&
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
      this.definition.params.status === "open" &&
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
      this.definition.params.category &&
      oldDefinition.params.category &&
      this.definition.params.category !== oldDefinition.params.category
    ) {
      doUpdate = () => {
        Topic.update(topic, {
          category_id: this.definition.params.category,
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
    data.oldDefinition = this.definition;
    data.oldRefresh = () => this.refreshTopics();
    this.setDragDataUpstream(data);
  }
}
