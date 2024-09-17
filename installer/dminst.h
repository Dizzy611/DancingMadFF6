#ifndef DMINST_H
#define DMINST_H

#include <QMainWindow>

QT_BEGIN_NAMESPACE
namespace Ui {
class DMInst;
}
QT_END_NAMESPACE

class DMInst : public QMainWindow
{
    Q_OBJECT

public:
    DMInst(QWidget *parent = nullptr);
    ~DMInst();

private slots:
    void on_ROMSelectBrowse_clicked();

    void on_ROMSelectLine_textChanged(const QString &arg1);

    void on_goButton_clicked();

private:
    Ui::DMInst *ui;
};
#endif // DMINST_H
