name: Build and Commit Docker Image Tag

on:
  workflow_dispatch:

env:
  KANIKO_CACHE_ARGS: "--cache=false --cache-copy-layers=false"
  AWS_REGION: "eu-north-1"
  ECR_URL: "360570401350.dkr.ecr.eu-north-1.amazonaws.com"
  ECR_REPOSITORY: "test"

permissions:
  contents: write

jobs:
  build-and-push:
    runs-on: local-runner

    steps:
      - name: Clone repo
        uses: actions/checkout@v3

      - name: AWS CLI install
        run: |
          curl -LO https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
          unzip awscli-exe-linux-x86_64.zip
          ./aws/install -i ${{ github.workspace }}/aws-cli -b ${{ github.workspace }}/aws-cli/bin
          export PATH=${{ github.workspace }}/aws-cli/bin:$PATH
          aws --version

      - name: current date 
        id: date
        run: echo "date=$(date +'%Y-%m-%d-%H-%M-%S')" >> $GITHUB_OUTPUT

      - name: ECR auth for Kaniko
        run: |
          export PATH=${{ github.workspace }}/aws-cli/bin:$PATH
          mkdir -p ${{ github.workspace }}/kaniko/.docker
          AUTH_STRING=$(echo -n AWS:$(aws ecr get-login-password --region $AWS_REGION) | base64 | tr -d '\n')
          echo "{\"auths\":{\"${{ env.ECR_URL }}\":{\"auth\":\"${AUTH_STRING}\"}}}" > ${{ github.workspace }}/kaniko/.docker/config.json

      - name: build and push Docker image with Kaniko
        uses: addnab/docker-run-action@v3
        with:
          image: gcr.io/kaniko-project/executor:v1.23.2-debug 
          options: "--privileged -v ${{ github.workspace }}/kaniko/.docker:/kaniko/.docker -v ${{ github.workspace }}:/github/workspace"
          run: |
            /kaniko/executor \
              --dockerfile=/github/workspace/Dockerfile \
              --context=dir:///github/workspace \
              --destination=${{ env.ECR_URL }}/${{ env.ECR_REPOSITORY }}:${{ steps.date.outputs.date }} \
              ${{ env.KANIKO_CACHE_ARGS }} \
              --push-retry=5 \
              --verbosity=debug
        env:
          AWS_REGION: ${{ env.AWS_REGION }}
          ECR_URL: ${{ env.ECR_URL }}
          ECR_REPOSITORY: ${{ env.ECR_REPOSITORY }}