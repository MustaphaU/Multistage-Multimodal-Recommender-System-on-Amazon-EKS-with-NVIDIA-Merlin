# Multistage Multimodal Recommender System on Amazon EKS

A production-grade multistage recommender system deployed on Kubernetes, combining two-tower retrieval, DLRM ranking, multimodal item embeddings, and a real-time behavioral personalization loop.  

**Model serving pipeline**
![Model serving architecture](static/Model_serving.png)
---

## MLOps Architecture

![MLOps architecture](static/MLOps_arch_updated.png)
---

## Publications
1. Towards Data Science

[Deploying a Multistage Multimodal Recommender System on Amazon EKS featuring Bloom Filters, Feature Caching, and Contextual Recommendations](https://towardsdatascience.com/deploying-a-multistage-multimodal-recommender-system-on-amazon-eks-featuring-bloom-filters-feature-caching-and-contextual-recommendations)

---
## Video Demo
Click to watch the Demo
[![Video Demo](static/github_thumbnail.png)](https://youtu.be/nNC8G7wBpBA)
## How it works

A user request triggers a 14-stage ensemble served by NVIDIA Triton Inference Server on EKS:

<!-- ![Illustration of Client Request processing](static/TritonProcessingRequests.png) -->

1. **Feast user lookup** — fetches user features (age, gender, `top_category`) from a Redis online store
2. **NVT transforms** — applies the same NVTabular preprocessing workflow used during training to user, item, and context features
3. **Two-Tower retrieval** — encodes the user query and searches a FAISS index of item embeddings to retrieve the top-N candidates
4. **Bloom filter** — removes items the user has already seen using a Redis/Valkey Bloom filter
5. **Feast item lookup** — resolves item features (category, price, gender) from a numpy in-memory cache loaded at startup (~0.5ms vs ~195ms for a live Feast round trip)
6. **Multimodal embedding lookup** — attaches CLIP image and sentence-transformer text embeddings (PCA-reduced to 64-dim each) to each candidate
7. **DLRM ranking** — scores the filtered candidates; a reranker reranks and samples from the scored candidates and  results are returned to the caller enriched with DynamoDB item metadata

---

## Real-time behavioral personalization

`top_category` — the user's dominant item category over the past 24 hours — is updated in near real-time without retraining:


- When a user interacts with an item, the serving Lambda adds it to a Redis sorted set (`user:{id}:recent_items`) and enqueues an SQS message
- The `recsys-feature-computation` Lambda triggers on that message, recomputes `top_category` from the sorted set, and writes it to both the **Feast online store** (Redis) for immediate serving and the **S3 offline store** (Parquet) for the next incremental training run
- The incremental training pipeline reads the S3 offline store to override stale Feast historical features, eliminating training/serving skew for `top_category`

---

## Stack

| Layer | Technology |
|---|---|
| Model serving | NVIDIA Triton Inference Server |
| Orchestration | Amazon EKS, Karpenter, Kubernetes HPA |
| Feature store | Feast (Redis online store, S3 offline store) |
| Behavioral cache | Amazon ElastiCache (Redis/Valkey) |
| Item metadata | Amazon DynamoDB |
| Serving Lambda | AWS Lambda + Function URL |
| Real-time features | AWS SQS → Lambda → Feast + S3 |
| Training pipeline | Kubeflow Pipelines on EKS |
| Preprocessing and Training | NVIDIA NVTabular, Merlin-Tensorflow |

---

## Deployment

Full deployment instructions: [Docs/documentation.md](Docs/documentation.md)

---

## Citation

```bibtex
@article{momoh2026multistage,
  title={Deploying a Multistage Multimodal Recommender System on Amazon Elastic Kubernetes Service},
  author={Momoh, Mustapha Unubi},
  journal={Towards Data Science},
  year={2026},
  month={May},
  url={https://towardsdatascience.com/deploying-a-multistage-multimodal-recommender-system-on-amazon-eks-featuring-bloom-filters-feature-caching-and-contextual-recommendations}
}
```
