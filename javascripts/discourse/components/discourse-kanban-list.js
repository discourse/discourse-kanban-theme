import Component from "@ember/component";
import { inject as service } from "@ember/service";
import discourseComputed, { bind, on } from "discourse-common/utils/decorators";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Topic from "discourse/models/topic";
import showModal from "discourse/lib/show-modal";
import I18n from "I18n";
import { next } from "@ember/runloop";

export default Component.extend({
  tagName: "div",
  classNames: "discourse-kanban-list",
  classNameBindings: ["acceptDrag"],
  kanbanHelper: service(),
  dialog: service(),

  @discourseComputed("definition.title")
  renderedTitle(title) {
    return title;
  },

  loadTopics() {
    this.set("loading", true);

    this.refreshTopics();
  },

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
  },

  didInsertElement() {
    this._super();
    next(this._setupIntersectionObserver);
  },

  @bind
  _setupIntersectionObserver() {
    if (!this.element || this.isDestroying || this.isDestroyed) {
      return;
    }
    this.set(
      "io",
      new IntersectionObserver((entries) => {
        if (entries[0].intersectionRatio <= 0) {
          return;
        }
        this.send("loadMore");
      })
    );
    this.io.observe(this.element.querySelector(".list-bottom"));
  },

  @on("willDestroyElement")
  _removeIntersectionObserver() {
    this.io?.disconnect();
  },

  dragLeave(event) {
    event.preventDefault();
    this.set("acceptDrag", false);
  },

  dragOver(event) {
    event.preventDefault();
    this.set("acceptDrag", true);
  },

  drop() {
    this.send("dropped");
    this.set("acceptDrag", false);
  },

  actions: {
    loadMore() {
      if (!this.list && !this.loading) {
        return this.loadTopics(); // Initial load
      }

      if (this.loading || !this.list.canLoadMore || this.loadingMore) {
        return;
      }

      this.set("loadingMore", true);
      this.list.loadMore().then(() => this.set("loadingMore", false));
    },

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
          return showModal("assign-user", {
            model: {
              topic,
              username: newUsername,
              onSuccess: () => {
                this.refreshTopics();
                oldRefresh();
              },
            },
          });
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
    },

    setDragData(data) {
      data.oldDefinition = this.definition;
      data.oldRefresh = () => this.refreshTopics();
      this.setDragData(data);
    },
  },
});
