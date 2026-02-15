#!/usr/bin/env node
/**
 * Direct Codex OAuth login — no onboard wizard prompts.
 * Prints the auth URL clearly for the user to copy.
 * Saves credentials into BOTH default (~/.openclaw) and dev (~/.openclaw-dev) profiles.
 */
import { loginOpenAICodex } from "@mariozechner/pi-ai";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import * as readline from "node:readline";

const home = os.homedir();

// Write to both default and dev profiles so `bot full` (--dev mode) works too.
const PROFILES = [
  { name: "default", stateDir: path.join(home, ".openclaw") },
  { name: "dev", stateDir: path.join(home, ".openclaw-dev") },
];

function log(msg) {
  console.log(`[codex-oauth] ${msg}`);
}

function readJsonFile(fp) {
  try {
    return JSON.parse(fs.readFileSync(fp, "utf-8")) || {};
  } catch {
    return {};
  }
}

function writeJsonFile(fp, data) {
  fs.mkdirSync(path.dirname(fp), { recursive: true });
  fs.writeFileSync(fp, JSON.stringify(data, null, 2));
  fs.chmodSync(fp, 0o600);
}

let rl = null;
function getRL() {
  if (!rl) {
    rl = readline.createInterface({ input: process.stdin, output: process.stderr });
  }
  return rl;
}
function closeRL() {
  if (rl) { rl.close(); rl = null; }
}
function promptLine(question) {
  return new Promise((resolve) => {
    getRL().question(question, (answer) => resolve(answer.trim()));
  });
}

function saveCredsToProfile(profile, creds) {
  const agentDir = path.join(profile.stateDir, "agents", "main", "agent");
  const authPath = path.join(agentDir, "auth-profiles.json");
  const cfgPath = path.join(profile.stateDir, "openclaw.json");

  // Skip non-default profiles if their state dir doesn't exist
  if (profile.name !== "default" && !fs.existsSync(profile.stateDir)) {
    log(`跳过 ${profile.name} profile（${profile.stateDir} 不存在）`);
    return;
  }

  // auth-profiles.json
  const store = readJsonFile(authPath);
  store.version = store.version || 1;
  store.profiles = store.profiles || {};
  store.profiles["openai-codex:default"] = {
    type: "oauth",
    provider: "openai-codex",
    access: creds.access,
    refresh: creds.refresh || "",
    expires: creds.expires || (Date.now() + 3600000),
    ...(creds.accountId ? { accountId: creds.accountId } : {}),
  };
  writeJsonFile(authPath, store);

  // openclaw.json
  const cfg = readJsonFile(cfgPath);
  const auth = (cfg.auth = cfg.auth || {});
  const profiles = (auth.profiles = auth.profiles || {});
  profiles["openai-codex:default"] = { provider: "openai-codex", mode: "oauth" };
  const order = (auth.order = auth.order || {});
  order["openai-codex"] = [
    "openai-codex:default",
    ...(order["openai-codex"] || []).filter((x) => x !== "openai-codex:default"),
  ];
  const agents = (cfg.agents = cfg.agents || {});
  const defaults = (agents.defaults = agents.defaults || {});
  const model = (defaults.model = defaults.model || {});
  model.primary = "openai-codex/gpt-5.2-codex";
  writeJsonFile(cfgPath, cfg);

  log(`已更新 [${profile.name}]: ${cfgPath}`);
}

async function main() {
  log("============================================");
  log("Codex OAuth 浏览器授权（直连模式）");
  log("");
  log("步骤：");
  log("  1. 下方会打印 https://auth.openai.com/... URL");
  log("  2. 复制到浏览器打开，完成登录");
  log("  3a. 自动回调成功 → 终端自动完成");
  log("  3b. 自动回调失败 → 复制浏览器跳转后的完整地址");
  log("      粘贴回终端按 Enter");
  log("============================================");
  log("");

  try {
    const creds = await loginOpenAICodex({
      onAuth: ({ url }) => {
        console.log("");
        console.log("========== 复制下面的 URL 到浏览器打开 ==========");
        console.log("");
        console.log(url);
        console.log("");
        console.log("=================================================");
        console.log("");
      },
      onPrompt: async (prompt) => {
        return await promptLine((prompt.message || "粘贴回调 URL 或授权码") + ": ");
      },
      onManualCodeInput: async () => {
        return await promptLine("等待自动回调... 或粘贴回调 URL 按 Enter: ");
      },
      onProgress: (msg) => log(msg),
    });

    closeRL();

    if (!creds || !creds.access) {
      log("OAuth 未返回有效凭据。");
      if (creds) log("返回字段: " + JSON.stringify(Object.keys(creds)));
      process.exit(1);
    }

    log("OAuth 登录成功！保存凭据到所有 profile...");
    for (const profile of PROFILES) {
      saveCredsToProfile(profile, creds);
    }

    log("");
    log("授权完成！默认模型: openai-codex/gpt-5.2-codex");
    log("运行 bot auth-status 查看状态，bot full 启动服务。");
    process.exit(0);
  } catch (err) {
    closeRL();
    console.error(`\n[codex-oauth] OAuth 失败: ${err.message || err}`);
    console.error("参考: https://docs.openclaw.ai/start/faq");
    process.exit(1);
  }
}

main();
