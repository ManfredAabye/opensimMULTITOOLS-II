(function () {
    const payload = window.osmtoolUiData;
    if (!payload) {
        return;
    }

    const moduleSelect = document.getElementById('module');
    const actionSelect = document.getElementById('action');
    const profileSelect = document.getElementById('profile');
    const descriptionNode = document.getElementById('action-description');
    const fieldRows = Array.from(document.querySelectorAll('.action-field'));
    const targetSelect = document.getElementById('field-target');

    if (!moduleSelect || !actionSelect || !profileSelect) {
        return;
    }

    function currentModule() {
        return payload.catalog[moduleSelect.value] || null;
    }

    function currentAction() {
        const moduleData = currentModule();
        if (!moduleData) {
            return null;
        }
        return moduleData.actions[actionSelect.value] || null;
    }

    function rebuildActionOptions() {
        const moduleData = currentModule();
        if (!moduleData) {
            return;
        }

        const previous = actionSelect.value;
        actionSelect.innerHTML = '';

        Object.entries(moduleData.actions).forEach(([actionKey, actionData], index) => {
            if (Array.isArray(actionData.profiles) && !actionData.profiles.includes(profileSelect.value)) {
                return;
            }
            const option = document.createElement('option');
            option.value = actionKey;
            option.textContent = actionData.label;
            if (actionKey === previous || (!moduleData.actions[previous] && index === 0)) {
                option.selected = true;
            }
            actionSelect.appendChild(option);
        });
    }

    function rebuildTargetOptions() {
        if (!targetSelect) {
            return;
        }

        const targetField = payload.fields.target;
        const options = (targetField.target_by_profile && targetField.target_by_profile[profileSelect.value]) || [];
        const previous = targetSelect.value;
        targetSelect.innerHTML = '';

        options.forEach((optionValue, index) => {
            const option = document.createElement('option');
            option.value = optionValue;
            option.textContent = optionValue;
            if (optionValue === previous || (!options.includes(previous) && index === 0)) {
                option.selected = true;
            }
            targetSelect.appendChild(option);
        });
    }

    function updateVisibleFields() {
        const actionData = currentAction();
        const visible = new Set(actionData ? actionData.fields : []);

        fieldRows.forEach((row) => {
            const shouldShow = visible.has(row.dataset.field);
            row.classList.toggle('is-hidden', !shouldShow);
        });

        rebuildTargetOptions();
        if (descriptionNode && actionData) {
            descriptionNode.textContent = actionData.description;
        }
    }

    moduleSelect.addEventListener('change', () => {
        rebuildActionOptions();
        updateVisibleFields();
    });

    profileSelect.addEventListener('change', () => {
        rebuildActionOptions();
        updateVisibleFields();
    });
    actionSelect.addEventListener('change', updateVisibleFields);

    rebuildActionOptions();
    updateVisibleFields();
})();