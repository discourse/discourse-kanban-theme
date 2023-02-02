import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import renderTag from "discourse/lib/render-tag";
import DiscourseURL from "discourse/lib/url";

export default class KanbanCard extends Component {
  classNameBindings = [":topic-card", "dragging", "topic.unseen:topic-unseen"];
  attributeBindings = ["draggable"];
  draggable = true;

  dragStart(event) {
    this.set("dragging", true);
    this.setDragData({ topic: this.topic });
    event.dataTransfer.setData("topic", this.topic);
  }

  dragEnd() {
    this.set("dragging", false);
  }

  click() {
    DiscourseURL.routeTo(this.topic.lastUnreadUrl);
  }

  @discourseComputed("tags")
  showTags(tags) {
    return settings.show_tags && tags.length;
  }

  @discourseComputed("topic.tags", "definition.params.tags")
  tags(topicTags, definitionTag) {
    return topicTags
      .filter((t) => t !== definitionTag)
      .map((t) => renderTag(t));
  }
}
