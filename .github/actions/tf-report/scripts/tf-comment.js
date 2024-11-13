/* based on: https://gaunacode.com/deploying-terraform-at-scale-with-github-actions */

const fs = require("node:fs");

const {
  PLAN_TXT,
  ENV_NAME,
  OUTCOME_FMT,
  OUTCOME_INIT,
  OUTCOME_VALIDATE,
  OUTCOME_PLAN,
} = process.env;

const plan = fs.readFileSync(PLAN_TXT, "utf8");

const maxGitHubBodyCharacters = 65536;
const maxBodyCharacters = maxGitHubBodyCharacters - 1536;

function chunkSubstr(str, size) {
  const numChunks = Math.ceil(str.length / size);
  const chunks = [];
  for (let i = 0, o = 0; i < numChunks; i++, o += size) {
    chunks.push(str.substring(o, o + size));
  }
  return chunks;
}

const chunks = chunkSubstr(plan, maxBodyCharacters);

async function githubComment({ github, context }) {
  const envComment = ENV_NAME ? ` - ${ENV_NAME}` : "";

  let output = "";

  if (chunks.length) {
    output += `## Terraform Summary${envComment}\n\n`;
    if (OUTCOME_FMT) output += `#### Format and Style: **${OUTCOME_FMT}**\n`;
    if (OUTCOME_INIT) output += `#### Initialization: **${OUTCOME_INIT}**\n`;
    if (OUTCOME_VALIDATE)
      output += `#### Validation: **${OUTCOME_VALIDATE}**\n`;
    if (OUTCOME_PLAN) output += `#### Plan: **${OUTCOME_PLAN}**\n`;

    await github.rest.issues.createComment({
      issue_number: context.issue.number,
      owner: context.repo.owner,
      repo: context.repo.repo,
      body: output,
    });

    for (let i = 0; i < chunks.length; i++) {
      output = `## Terraform Plan${envComment} - Part ${i + 1} of ${
        chunks.length
      }\n\n`;
      output += "<details>\n\n";
      output += "<summary>Show Plan</summary>\n\n";
      output += "```\n\n";
      output += `${chunks[i]}\n\n`;
      output += "```\n\n";
      output += "</details>\n\n";
      output += `**Triggered by @${context.actor}, on Event \`${context.eventName}\`**\n`;

      await github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: output,
      });
    }
  }
}

module.exports = githubComment;
