import { displayConnector } from '../../lib/kanban-utilities';

export default {
    shouldRender(args, component) {
        return displayConnector(component.get('category.slug'));
    }
}