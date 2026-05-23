# On-Device Models for CarpCowork

This directory holds `.mlpackage` bundles for on-device inference.
**These files are git-ignored** due to their size — each model must be generated locally.

## Export Pipeline

### 1. Train / Obtain a nanoGPT Checkpoint

```bash
# Clone Karpathy's nanoGPT
git clone https://github.com/karpathy/nanoGPT
cd nanoGPT

# Train on your instruction dataset (iOS agentic tasks)
# See data/ios-tasks/ for the recommended dataset format
python train.py config/train_ios_agent.py
```

### 2. Fine-Tune for iOS Agentic Tasks

The model should be fine-tuned on a dataset of:
- File read/write instructions
- Clipboard manipulation tasks
- Shortcuts automation examples
- iOS-specific code generation

Dataset format (JSONL):
```jsonl
{"prompt": "<|user|>\nRead the file at /Documents/notes.txt\n<|assistant|>\n", "completion": "<tool>file_read({\"path\": \"/Documents/notes.txt\"})</tool>"}
```

### 3. Export to Core ML

```python
# export_coreml.py
import torch
import coremltools as ct
from model import GPT, GPTConfig

# Load checkpoint
checkpoint = torch.load('out/ckpt.pt', map_location='cpu')
config = GPTConfig(**checkpoint['model_args'])
model = GPT(config)
model.load_state_dict(checkpoint['model'])
model.eval()

# Trace the model
seq_len = 512
example_input = torch.zeros(1, seq_len, dtype=torch.long)
traced = torch.jit.trace(model, example_input)

# Convert to Core ML
mlmodel = ct.convert(
    traced,
    inputs=[ct.TensorType(name="input_ids", shape=(1, seq_len), dtype=int)],
    outputs=[ct.TensorType(name="logits")],
    compute_units=ct.ComputeUnit.ALL,  # Uses Apple Neural Engine where available
    minimum_deployment_target=ct.target.iOS17,
)
mlmodel.save("NanoGPT-CodeAssist-v1.mlpackage")
```

### 4. Place Files Here

```
CoreMLModels/
├── NanoGPT-CodeAssist-v1.mlpackage/    ← compiled model
├── NanoGPT-CodeAssist-v1.vocab.json    ← BPE vocabulary
└── NanoGPT-CodeAssist-v1.merges.txt    ← BPE merge rules
```

The `ModelBundleLoader` discovers all `.mlpackage` files in this directory at runtime,
as long as matching `vocab.json` + `merges.txt` files are present with the same stem.

## RL Fine-Tuning Notes

For reward-model based RL training (RLHF-style):

**Reward signal:** Task completion — did the agent's sequence of tool calls successfully accomplish the goal?

**Suggested approach:**
1. Generate rollouts from the SFT (supervised fine-tuned) nanoGPT checkpoint.
2. Score each rollout: +1 if task completed correctly, -1 if not, 0 if partial.
3. Use PPO or GRPO (Karpathy's preferred simple RL) to update the policy.
4. Re-export the RL-trained checkpoint to Core ML.

This RL pipeline is not implemented in this prototype — it is documented here for future iteration.

## Apple Foundation Models (iOS 18.1+)

If running on iOS 18.1+ with Apple Intelligence enabled, `OnDeviceModelProvider` will
automatically prefer the system on-device LLM via the `FoundationModels` framework
(no model files needed — the system model is used directly).

Drop any `.mlpackage` files here only for iOS 17 compatibility or custom fine-tuned models.
