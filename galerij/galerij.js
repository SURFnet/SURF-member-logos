"use strict";

const CSV_URL = "orgs.csv";
const LOGO_DIRECTORY = "128x128/";
const LOGO_FULL_DIRECTORY = "bron/";
const statusElement = document.getElementById("status");
const galleryElement = document.getElementById("gallery");

/**
 * Parse CSV text while respecting quoted fields, escaped quotes, and newlines in quoted fields.
 * @param {string} text
 * @returns {string[][]}
 */
function parseCsv(text) {
    const rows = [];
    let row = [];
    let field = "";
    let insideQuotes = false;

    for (let index = 0; index < text.length; index += 1) {
        const character = text[index];

        if (character === '"') {
            if (insideQuotes && text[index + 1] === '"') {
                field += '"';
                index += 1;
            } else {
                insideQuotes = !insideQuotes;
            }
        } else if (character === "," && !insideQuotes) {
            row.push(field);
            field = "";
        } else if ((character === "\n" || character === "\r") && !insideQuotes) {
            if (character === "\r" && text[index + 1] === "\n") {
                index += 1;
            }
            row.push(field);
            rows.push(row);
            row = [];
            field = "";
        } else {
            field += character;
        }
    }

    if (field !== "" || row.length > 0) {
        row.push(field);
        rows.push(row);
    }

    return rows;
}

/**
 * Convert CSV records to the fields needed by the gallery.
 * The source file contains comment-prefixed metadata/header lines.
 * @param {string} text
 * @returns {{guid: string, code: string, name: string}[]}
 */
function organizationsFromCsv(text) {
    return parseCsv(text.replace(/^\uFEFF/, ""))
        .filter((row) => row.length >= 3 && row.some((field) => field.trim() !== ""))
        .filter((row) => !row[0].trim().startsWith("#"))
        .filter((row) => row[0].trim().toLowerCase() !== "crm_guid")
        .map((row) => ({
            guid: row[0].trim(), code: row[1].trim(), name: row[2].trim()
        }))
        .filter((organization) => organization.guid && organization.name);
}

function setStatus(message, type) {
    statusElement.className = type ? `status ${type}` : "status";
    statusElement.setAttribute("role", type === "error" ? "alert" : "status");
    statusElement.replaceChildren();

    if (type === "error") {
        const p = document.createElement("p");

        const heading = document.createElement("strong");
        heading.textContent = message.heading;

        const desc = document.createElement("span")
        desc.textContent = message.detail;

        p.append(heading, desc);

        const retryButton = document.createElement("button");
        retryButton.type = "button";
        retryButton.textContent = "Try again";
        retryButton.addEventListener("click", loadOrganizations);

        statusElement.append(p, retryButton);
        return;
    }

    statusElement.textContent = message;
}

function createOrganizationCard(organization) {
    const item = document.createElement("li");
    item.className = "organization";

    const frame = document.createElement("div");
    frame.className = "logo-frame";

    const placeholder = document.createElement("span");
    placeholder.className = "logo-placeholder";
    placeholder.textContent = "Logo unavailable";
    placeholder.setAttribute("aria-hidden", "true");

    const link = document.createElement("a")
    link.class = "logo-link";
    link.href = `${LOGO_FULL_DIRECTORY}${encodeURIComponent(organization.guid)}.png`;

    const image = document.createElement("img");
    image.className = "logo-image";
    image.width = 128;
    image.height = 128;
    image.alt = `${organization.name} logo`;
    image.loading = "lazy";
    image.style.visibility = "hidden";
    image.addEventListener("load", () => {
        image.style.visibility = "visible";
        placeholder.hidden = true;
    });
    image.addEventListener("error", () => {
        image.style.visibility = "hidden";
        placeholder.hidden = false;
        item.classList.add("missing-logo");
    });
    image.src = `${LOGO_DIRECTORY}${encodeURIComponent(organization.guid)}.png`;

    link.append(image)
    frame.append(placeholder, link);

    const orgInfo = document.createElement("div");
    orgInfo.className = "organization-info";

    const name = document.createElement("span");
    name.className = "organization-name";
    name.textContent = organization.name;
    if (organization.code) {
        name.title = organization.code;
    }

    const code = document.createElement("span");
    code.className = "organization-code";
    code.textContent = organization.code ? organization.code : '&mdash;';

    const guid = document.createElement("span");
    guid.className = "organization-guid";
    guid.textContent = organization.guid;

    orgInfo.append(name, code, guid);

    item.append(frame, orgInfo);
    return item;
}

function renderOrganizations(organizations) {
    galleryElement.replaceChildren();

    if (organizations.length === 0) {
        const emptyState = document.createElement("li");
        emptyState.className = "empty-state";
        emptyState.textContent = "No organizations were found.";
        galleryElement.appendChild(emptyState);
        return;
    }

    const cards = organizations.map(createOrganizationCard);
    galleryElement.append(...cards);
}

async function loadOrganizations() {
    setStatus("Loading organizations\u2026");
    galleryElement.replaceChildren(...Array.from({length: 4}, () => {
        const skeleton = document.createElement("li");
        skeleton.className = "skeleton";
        skeleton.setAttribute("aria-hidden", "true");
        return skeleton;
    }));

    try {
        const response = await fetch(CSV_URL, {credentials: "same-origin"});
        if (!response.ok) {
            const error = new Error(`Unable to load organizations (HTTP ${response.status}).`);
            error.status = response.status;
            throw error;
        }

        const organizations = organizationsFromCsv(await response.text());
        renderOrganizations(organizations);
        setStatus(`${organizations.length} organization${organizations.length === 1 ? "" : "s"}`);
    } catch (error) {
        galleryElement.replaceChildren();
        if (error.status === 401 || error.status === 403) {
            setStatus({
                heading: "Access to the organization list was denied.", detail: "Please sign in to GitHub with an account that can access this repository, then try again."
            }, "error");
        } else {
            setStatus({
                heading: "The organization list could not be loaded.", detail: "Please check your connection or try again in a moment."
            }, "error");
        }
        console.error("Could not load orgs.csv", error);
    }
}


/* handle switching of guids */
document.body.classList.add("hide-guids")
document.getElementById("toggle-guids").addEventListener("change", (event) => {
    document.body.classList.toggle("hide-guids", !event.target.checked);
});
