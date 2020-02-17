import { displayConnector } from '../../lib/kanban-utilities';

export default {
    shouldRender(args, component) {

        if (settings.discovery_mode != "category"
            && settings.discovery_mode != "tag"
            && settings.discovery_mode != "@"
        ) {
            console.log('Kanban connector unable to load - settings.discovery_mode has incorrect value.');
            return false;
        }

        if (settings.display_list === "") return true;

        const displayList = settings.display_list.split("|");
        if(settings.discovery_mode === "category"){
            return displayConnector(component.get('category.slug'));
        }else if(settings.discovery_mode === "tag"){
            return displayConnector(component.get("selectedNavItem.tagId"));
        }else if(component.get("category.slug")){
            return displayConnector(component.get("category.slug"));
        }else{
            return displayConnector(component.get("selectedNavItem.tagId"));
        }
    }
}