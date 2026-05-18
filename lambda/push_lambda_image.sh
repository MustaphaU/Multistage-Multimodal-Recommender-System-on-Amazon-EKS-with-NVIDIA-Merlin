AWS_REGION=${1:-"us-east-1"}
AWS_ACCOUNT_ID=${2:-"ACCOUNT_ID"}

aws ecr create-repository --repository-name recsys-lambda --region $AWS_REGION || true
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker build --no-cache --platform linux/amd64 --provenance=false -f Dockerfile.lambda -t recsys-lambda .
docker tag recsys-lambda:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/recsys-lambda:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/recsys-lambda:latest

DIGEST=$(aws ecr describe-images \
  --repository-name recsys-lambda \
  --image-ids imageTag=latest \
  --region $AWS_REGION \
  --query 'imageDetails[0].imageDigest' \
  --output text)

aws lambda update-function-code \
  --function-name recsys-recommend \
  --image-uri $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/recsys-lambda@$DIGEST \
  --region $AWS_REGION

aws lambda wait function-updated \
  --function-name recsys-recommend \
  --region $AWS_REGION

echo "recsys-recommend updated"