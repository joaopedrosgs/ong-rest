package controller

import (
	"projeto_bd/model"

	"github.com/jmoiron/sqlx"
	"github.com/labstack/echo"
	_ "github.com/lib/pq"
)

type LogController struct {
	conn *sqlx.DB
}

func NewLogController() *LogController {
	p := new(LogController)
	var err error
	p.conn, err = sqlx.Connect("postgres", "postgres://root@localhost:5432/trabalho?sslmode=disable")
	if err != nil {
		println("Falha ao conectar: " + err.Error())
		return nil
	}
	return p
}
func (p *LogController) Get(c echo.Context) error {

	logs := []model.LogBeneficiario{}
	err := p.conn.Select(&logs, "select * from log_beneficiario")
	if err != nil {
		println("Falha ao buscar logs: " + err.Error())
		return err
	}
	c.JSON(200, logs)
	return nil
}
