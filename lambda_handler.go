package main

import (
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
)

var instId = "i-0329f22f9ea8e12bc"

func describeInstance(icon string, state string, dns string) string {
	if dns == "" {
		return fmt.Sprintf("%s Server is %s and does not have a public DNS name", icon, state)
	}
	return fmt.Sprintf("%s Server is %s and has public DNS name %s", icon, state, dns)
}

func Handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	sess, err := session.NewSession(&aws.Config{Region: aws.String("us-west-1")})
	if err != nil {
		fmt.Println("failed to create session")
		return events.APIGatewayProxyResponse{}, err
	}

	client := ec2.New(sess)

	instanceFilter := &ec2.DescribeInstancesInput{
		InstanceIds: []*string{
			&instId,
		},
	}

	desc, err := client.DescribeInstances(instanceFilter)
	if err != nil {
		fmt.Println("failed to describe instances")
		return events.APIGatewayProxyResponse{}, err
	}

	instance := desc.Reservations[0].Instances[0]
	state := *instance.State.Name
	dns := *instance.PublicDnsName

	switch state {
	case "running":
		return events.APIGatewayProxyResponse{
			Body:       describeInstance("✅", state, dns),
			StatusCode: 200,
		}, nil
	case "pending":
		return events.APIGatewayProxyResponse{
			Body:       describeInstance("⏳", state, dns),
			StatusCode: 200,
		}, nil
	}

	// Instance not running, either print out the form to start it (for a GET) or actually start it (for a POST).
	if request.HTTPMethod == "GET" {
		body := `
			<html>
				<body>
					<p>The server isn't running yet. Would you like to start it?</p>
					<form action="" method="post">
						<input type="submit" value="Start instance"/>
					</form>
				</body>
			</html>
		`
		return events.APIGatewayProxyResponse{
			Body:       body,
			Headers:    map[string]string{"content-type": "text/html"},
			StatusCode: 200,
		}, nil
	}

	// We should only get GET or POST requests
	if request.HTTPMethod != "POST" {
		return events.APIGatewayProxyResponse{
			Body:       fmt.Sprint("Unrecognized HTTP method: %s", request.HTTPMethod),
			StatusCode: 200,
		}, nil
	}

	fmt.Printf("starting instance %s\n", instId)
	_, err = client.StartInstances(&ec2.StartInstancesInput{
		InstanceIds: []*string{
			&instId,
		},
	})
	if err != nil {
		return events.APIGatewayProxyResponse{
			Body:       "❌ Failed to start instance. Instance is likely transitioning between states. Try again shortly.",
			StatusCode: 200,
		}, nil
	}

	return events.APIGatewayProxyResponse{
		Body:       "⏳ Instance is starting, refresh this page to see status",
		StatusCode: 200,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
