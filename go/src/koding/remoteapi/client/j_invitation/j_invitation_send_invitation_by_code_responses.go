package j_invitation

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// JInvitationSendInvitationByCodeReader is a Reader for the JInvitationSendInvitationByCode structure.
type JInvitationSendInvitationByCodeReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *JInvitationSendInvitationByCodeReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewJInvitationSendInvitationByCodeOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewJInvitationSendInvitationByCodeUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewJInvitationSendInvitationByCodeOK creates a JInvitationSendInvitationByCodeOK with default headers values
func NewJInvitationSendInvitationByCodeOK() *JInvitationSendInvitationByCodeOK {
	return &JInvitationSendInvitationByCodeOK{}
}

/*JInvitationSendInvitationByCodeOK handles this case with default header values.

Request processed successfully
*/
type JInvitationSendInvitationByCodeOK struct {
	Payload *models.DefaultResponse
}

func (o *JInvitationSendInvitationByCodeOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JInvitation.sendInvitationByCode][%d] jInvitationSendInvitationByCodeOK  %+v", 200, o.Payload)
}

func (o *JInvitationSendInvitationByCodeOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewJInvitationSendInvitationByCodeUnauthorized creates a JInvitationSendInvitationByCodeUnauthorized with default headers values
func NewJInvitationSendInvitationByCodeUnauthorized() *JInvitationSendInvitationByCodeUnauthorized {
	return &JInvitationSendInvitationByCodeUnauthorized{}
}

/*JInvitationSendInvitationByCodeUnauthorized handles this case with default header values.

Unauthorized request
*/
type JInvitationSendInvitationByCodeUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *JInvitationSendInvitationByCodeUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/JInvitation.sendInvitationByCode][%d] jInvitationSendInvitationByCodeUnauthorized  %+v", 401, o.Payload)
}

func (o *JInvitationSendInvitationByCodeUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}
