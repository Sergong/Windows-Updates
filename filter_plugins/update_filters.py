def extract_category_updates(category_name, updates_dict):
    result = []
    for update_id, update in updates_dict.items():
        for cat in update.get('categories', []):
            if category_name.lower() in cat.lower():
                result.append((update_id, update))
                break
    return result

def extract_and_format_lines(category_name, categorized_updates):
    """
    Return a list of formatted lines for a given category.
    """
    updates = categorized_updates.get(category_name, [])
    lines = [f"{category_name} ({len(updates)} update{'s' if len(updates) != 1 else ''})"]
    for _, update in updates:
        lines.append(f"  • {update.get('title', '<no title>')}")
    lines.append("")  # add blank line for spacing
    return lines

class FilterModule(object):
    def filters(self):
        return {
            'extract_category_updates': extract_category_updates,
            'extract_and_format_lines': extract_and_format_lines,
        }
