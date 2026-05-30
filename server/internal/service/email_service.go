package service

import (
	"fmt"
	"net/smtp"
)

type EmailService struct {
	host string
	port string
	from string
}

func NewEmailService(host, port, from string) *EmailService {
	return &EmailService{host: host, port: port, from: from}
}

func (s *EmailService) Send(to, subject, body string) error {
	addr := fmt.Sprintf("%s:%s", s.host, s.port)
	msg := []byte(
		"From: " + s.from + "\r\n" +
			"To: " + to + "\r\n" +
			"Subject: " + subject + "\r\n" +
			"Content-Type: text/plain; charset=UTF-8\r\n" +
			"\r\n" + body,
	)
	return smtp.SendMail(addr, nil, s.from, []string{to}, msg)
}
