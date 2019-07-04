package controller

import (
	"errors"
	"projeto_bd/model"

	"github.com/jmoiron/sqlx"
	"github.com/labstack/echo"
	_ "github.com/lib/pq"
)

type OngController struct {
	conn *sqlx.DB
}

func NewOngController() *OngController {
	p := new(OngController)
	var err error
	p.conn, err = sqlx.Connect("postgres", "postgres://root@localhost:5432/trabalho?sslmode=disable")
	if err != nil {
		println("Falha ao conectar: " + err.Error())
		return nil
	}
	return p
}
func (p *OngController) Get(c echo.Context) error {
	cpf := c.Param("codigo")
	if cpf == "" {
		ongs := []model.Ong{}
		err := p.conn.Select(&ongs, "select * from ong")
		if err != nil {
			println("Falha ao buscar ongs: " + err.Error())
			return err
		}
		return c.JSON(200, ongs)
	} else {
		ong := model.Ong{}
		err := p.conn.Get(&ong, "select * from ong where codigo=$1", cpf)
		if err != nil {
			println("Falha ao buscar ong: " + err.Error())
			return err
		}
		return c.JSON(200, ong)
	}

}
func (p *OngController) Put(c echo.Context) error {

	ong := new(model.Ong)
	err := c.Bind(ong)
	if err != nil {
		println("Falha ao dar parse na ong: " + err.Error())
		return err
	}

	_, err = p.conn.Exec("UPDATE ong"+
		"set nome = $1,"+
		"rua = $2,"+
		"bairro = $3,"+
		"cidade = $4,"+
		"cep = $5,"+
		"numero=$6"+
		"cpf_voluntario_responsavel = %7"+
		"where codigo=$8",
		ong.Nome, ong.Rua, ong.Bairro, ong.Cidade, ong.Cep, ong.Numero, ong.CpfVoluntarioResponsavel, ong.Codigo)

	if err != nil {
		println("Falha ao atualizar ong: " + err.Error())
		return err
	}
	return c.JSON(200, ong)
}
func (p *OngController) Post(c echo.Context) error {
	ong := new(model.Ong)
	err := c.Bind(ong)
	if err != nil {
		println("Falha ao dar parse na ong: " + err.Error())
		return err
	}

	_, err = p.conn.Exec("INSERT into ong(nome, rua, bairro, cidade, cep,numero,  cpf_voluntario_responsavel) values($1, $2, $3, $4, $5, $6, $7)",
		ong.Nome, ong.Rua, ong.Bairro, ong.Cidade, ong.Cep, ong.Numero, ong.CpfVoluntarioResponsavel)

	if err != nil {
		println("Falha ao inserir ong: " + err.Error())
		return err
	}
	return c.JSON(200, ong)
}
func (p *OngController) Delete(c echo.Context) error {
	cpf := c.Param("codigo")
	if cpf == "" {
		return errors.New("Codigo vazio")

	}
	_, err := p.conn.Exec("delete from ong where codigo=$1", cpf)
	if err != nil {
		println("Falha ao deletar ong: " + err.Error())
		return err
	}
	return c.NoContent(400)
}
