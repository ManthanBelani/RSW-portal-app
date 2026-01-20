import {
  Box,
  Button,
  Card,
  Container,
  Divider,
  FormControl,
  FormControlLabel,
  FormLabel,
  Grid,
  IconButton,
  InputAdornment,
  Radio,
  RadioGroup,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { styled } from "@mui/material/styles";
import { useDispatch } from "react-redux";
import { format, isValid } from "date-fns";
import { useFormik } from "formik";
import React, { useEffect, useState } from "react";
import { useLocation, useNavigate, useParams } from "react-router";
import DoNotDisturbOnIcon from '@mui/icons-material/DoNotDisturbOn';

import { getBody } from "src/_services";
import {
  REQUEST_ACTIVE_PROPOSAL_LIST,
  REQUEST_CREATE_INVOICE,
  REQUEST_GENERATE_INVOICE,
  REQUEST_GET_CLIENTS_DATA,
  REQUEST_GET_CURRENCY_RATE,
  REQUEST_INVOICE_DELETE_ATTACHMENT,
  REQUEST_PROJECT_CLIENT_DATA,
  REQUEST_UPDATE_INVOICE,
  REQUEST_VIEW_INVOICE,
} from "src/_services/generateinvoice";
import {
  REQUEST_GET_CLIENTS_LIST,
  REQUEST_GET_COMPANY_LIST,
  REQUEST_GET_CURRENCY_LIST,
  REQUEST_GET_PROJECTS_LIST_USER,
} from "src/_services/utils";
import Page from "src/components/Page";
import useHandleError from "src/hooks/useHandleError";
import CustomDatePicker from "src/components/common/datePicker/CustomDatePicker";
import { downloadFile, hasPermission } from "src/utils/commonFunctions";
import { invoiceValidations } from "src/validation";
import { projectsActions, snackbarActions } from "src/_actions";
import AsyncAutocomplete from "src/components/customautocomplete/AsyncAutocomplete";
import { MultipleUploadInput } from "src/components/common/FileUploadInput/CustomUploadInput";
import Spacer from "src/components/common/Spacer";
import ConfirmationDialog from "src/components/common/dialogs/ConfirmationDialog";
import { CloseIcon } from "src/theme/overrides/CustomIcons";
import { REQUEST_GET_EDIT_ESTIMATE } from "src/_services/works";
import SelectProject from "src/sections/@dashboard/notes/SelectProject";
import { isArray, wrap } from "lodash";
import { column } from "stylis";
import IconButtonTooltip from "src/components/customiconbutton/IconButtonTooltip";
import { AddCircle } from "@mui/icons-material";
import { date } from "yup";

// Placeholder for new API call to get invoice count by date and client
const REQUEST_GET_INVOICES_BY_DATE = ({ date, clientId, clientName }) => {
  // Implement API call to fetch invoices for the given date and client
  // Example: return axios.post('/api/invoices/by-date', { date, clientId, clientName });
  return Promise.resolve({ data: { success: true, data: [] } }); // Mock response
};

const LabelStyle = styled(Typography)(({ theme }) => ({
  ...theme.typography.subtitle2,
  color: theme.palette.text.secondary,
  marginBottom: theme.spacing(1),
}));

const AddInvoice = (props) => {
  const { isEdit } = props;
  const navigate = useNavigate();
  const location = useLocation();
  const params = useParams();
  const dispatch = useDispatch();
  const { handleErrorState } = useHandleError();

  const { values: locationValues, filters: locationFilters } =
    location.state || {};

  const isCopy = location.state?.isCopy ?? false;
  const invoiceDatas = location.state?.invoiceData ?? null;
  const EstimatedData = location.state?.EstimatedData ?? null;

  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [isDeleteFile, setIsDeleteFile] = useState(false);
  const [clients, setClients] = useState([]);
  const [projects, setProjects] = useState([]);
  const [invoiceData, setInvoiceData] = useState(null);
  const [company, setCompany] = useState([]);
  const [currency, setCurrency] = useState([]);
  const [clientData, setClientData] = useState([]);
  const [isProjectLoading, setIsProjectLoading] = useState(false);
  const [isCurrencyLoading, setisCurrencyLoading] = useState(false);
  const [isClientLoading, setisClientLoading] = useState(false);
  const [isCompanyLoading, setisCompanyLoading] = useState(false);
  const [selectedProject, setSelectedProject] = useState(null);
  const [selectedClients, setSelectedClients] = useState(null);
  const [selectedCurrency, setSelectedCurrency] = useState(null);
  const [selectedCompany, setSelectedCompany] = useState(null);
  const [attachment, setAttachment] = useState(null);
  const [generateState, setGenerateState] = useState("");
  const [estimatedId, setEstimatedId] = useState("");
  const [goBackValuePassState, setGoBackValuePassState] = useState(
    locationValues ?? null
  );
  const [activeProposals, setActiveProposals] = useState([]);
  const [selectedActive, setSelectedActive] = useState(null);

  const handleRemovePaidAmount = (index) => {
    const updateForm = [...generateInvoiceFormik?.values?.work_paid_amount]
    updateForm.splice(index, 1);
    generateInvoiceFormik?.setFieldValue("work_paid_amount", updateForm)
  }

  const normlizedPaidAmountData = (paidAmountData, isCopy = false, isEdit = false) => {
    let normlized = []
    if (isCopy) {
      return [{
        paid_amount: 0,
        date: null,
        note: ""
      }]
    }
    if (Array.isArray(paidAmountData)) {
      normlized = paidAmountData.map((item) => ({
        paid_amount: Number(item.paid_amount) || 0,
        date: format(new Date(item.date), "yyyy-MM-dd") || null,
        note: item.note || ""
      }));
    }
    else if (paidAmountData && typeof paidAmountData === "object") {
      normlized = [{
        paid_amount: Number(paidAmountData.paid_amount) || 0,
        date: format(new Date(paidAmountData.date), "yyyy-MM-dd") || null,
        note: paidAmountData.note || "",
      }]
    }
    else {
      normlized = [{
        paid_amount: 0,
        date: null,
        note: ""
      }]
    }
    return normlized
  }

  const getCleanedFormData = (paid_amount) => {
    return paid_amount.filter((item) => {
      const hasAmount = Number(item.paid_amount) > 0;
      const hasDate = !!item.date;
      const hasNote = item.note;

      return hasAmount && hasDate && hasNote;
    })
  }

  const generateInvoiceFormik = useFormik({
    initialValues: {
      client: null,
      other_client: "",
      project: null,
      other_project: "",
      active: null,
      currency: null,
      client_address: "",
      company: null,
      invoice_amount: 0,
      currency_rate: 0,
      invoice_number: "",
      work_paid_amount: isEdit && invoiceDatas?.work_info?.work_paid_amount
        ? normlizedPaidAmountData(invoiceDatas?.work_info?.work_paid_amount, isEdit)
        : [{
          paid_amount: 0,
          date: null,
          note: ""
        }],
      work_price_amount: 0,
      is_paid: invoiceDatas?.work_info?.is_paid || 0,
      is_completed: invoiceDatas?.work_info?.is_completed || 0,
      invoice_date: isCopy
        ? new Date()
        : invoiceDatas?.invoice_date
          ? new Date(invoiceDatas.invoice_date)
          : new Date(),
      due_date: isCopy
        ? new Date(new Date().setDate(new Date().getDate() + 7))
        : invoiceDatas?.due_date
          ? new Date(invoiceDatas.due_date)
          : new Date(new Date().setDate(new Date().getDate() + 7)),
      work_start_date: null,
      work_end_date: null,
      work_title: "",
      reduce_label: "",
      reduce_amount: "",
      job_description: "",
      notice: "",
      attachment: null,
    },
    validateOnChange: true,
    validationSchema: invoiceValidations,
    validateOnBlur: true,
    onSubmit: (values, { setSubmitting }) => {
      const data = new FormData();
      data.append("client_id", values?.client || "");
      data.append("client_name", values?.other_client || "");
      data.append("currency", values?.currency?.id);
      data.append("currency_code", selectedCurrency?.currency_code || "");
      data.append("address", values?.client_address?.trimStart() || "");
      data.append("company", values?.company);
      data.append("rate", Number(values?.invoice_amount));
      data.append("invoice_no", values?.invoice_number);
      data.append('currency_rate', Number(values?.currency_rate) || 0)
      if (values?.invoice_date) {
        data.append("datefrom", format(values?.invoice_date, "yyyy-MM-dd"));
      }
      if (values?.due_date) {
        data.append("dateto", format(values?.due_date, "yyyy-MM-dd"));
      }
      data.append("discount_label", values?.reduce_label?.trimStart() || "");
      if (values?.reduce_amount) {
        data.append("discount", Number(values?.reduce_amount));
      }
      data.append("notice", values?.notice?.trimStart() || "");
      data.append("is_update", Boolean(isEdit) ? 1 : 0);

      if (values?.attachment) {
        Object.values(values?.attachment).forEach((fileData) => {
          data.append("attachment[]", fileData);
        });
      }

      const cleanedForm = getCleanedFormData(values?.work_paid_amount)

      data.append(
        "work_info",
        JSON.stringify({
          work_paid_amount: cleanedForm,
          price_amount: Number(values?.work_price_amount),
          is_paid: values?.is_paid,
          is_completed: values?.is_completed,
          ...(values?.work_start_date && {
            work_start_date: format(values?.work_start_date, "yyyy-MM-dd"),
          }),
          ...(values?.work_end_date && {
            work_end_date: format(values?.work_end_date, "yyyy-MM-dd"),
          }),
          ...(values?.work_title?.trimStart() && {
            work_title: values?.work_title?.trimStart(),
          }),
        })
      );

      if (generateState === "save_invoice") {
        const invoicePayload = new FormData();
        invoicePayload.append("client_id", values?.client || "");
        if (estimatedId) {
          invoicePayload.append("estimate_id", estimatedId || "");
        }
        invoicePayload.append("project_id", values?.project || "");
        invoicePayload.append("proposal_id", values?.active || "");
        invoicePayload.append("client_name", values?.other_client);
        invoicePayload.append("project_name", values?.other_project);
        if (values?.other_client || values?.other_project) {
          invoicePayload.append("is_external", 1);
        }
        invoicePayload.append("currency_id", values?.currency?.id);
        invoicePayload.append(
          "client_address",
          values?.client_address?.trim() ? values?.client_address?.trim() : ""
        );
        invoicePayload.append("company_id", values?.company || "");
        invoicePayload.append("invoice_rate", Number(values?.invoice_amount));
        invoicePayload.append("invoice_no", values?.invoice_number);
        invoicePayload.append('currency_rate', Number(values?.currency_rate) || 0)
        if (values?.invoice_date) {
          invoicePayload.append(
            "invoice_date",
            format(values?.invoice_date, "yyyy-MM-dd")
          );
        }
        if (values?.due_date) {
          invoicePayload.append(
            "due_date",
            format(values?.due_date, "yyyy-MM-dd")
          );
        }
        invoicePayload.append(
          "discount_label",
          values?.reduce_label?.trim() ? values?.reduce_label?.trim() : ""
        );
        invoicePayload.append(
          "discount_amount",
          Number(values?.reduce_amount) || 0
        );
        invoicePayload.append(
          "invoice_description",
          values?.job_description?.trim() ? values?.job_description?.trim() : ""
        );
        invoicePayload.append(
          "notice",
          values?.notice?.trim() ? values?.notice?.trim() : ""
        );
        invoicePayload.append("reference", values?.invoice_number || "");
        invoicePayload.append("hourly_rate", "");
        invoicePayload.append("expense_amount", "");
        invoicePayload.append("task_filter", "");
        invoicePayload.append("invoice_type", "invoice");
        invoicePayload.append("is_paid", values?.is_paid);
        invoicePayload.append(
          "work_info",
          JSON.stringify({
            work_paid_amount: cleanedForm,
            price_amount: Number(values?.work_price_amount),
            is_paid: values?.is_paid,
            is_completed: values?.is_completed,
            ...(values?.work_start_date && {
              work_start_date: format(values?.work_start_date, "yyyy-MM-dd"),
            }),
            ...(values?.work_end_date && {
              work_end_date: format(values?.work_end_date, "yyyy-MM-dd"),
            }),
            ...(values?.work_title?.trimStart() && {
              work_title: values?.work_title?.trimStart(),
            }),
          })
        );

        if (values?.attachment) {
          Object.values(values?.attachment).forEach((fileData) => {
            invoicePayload.append("attachment[]", fileData);
          });
        }

        if (Boolean(params?.invoiceId)) {
          invoicePayload.append("invoice_id", params?.invoiceId);

          REQUEST_UPDATE_INVOICE(invoicePayload)
            .then((res) => {
              const invoiceResponse = getBody(res);
              if (invoiceResponse?.success === true) {
                dispatch(
                  snackbarActions.showSnackbar(
                    invoiceResponse?.data?.message,
                    "success"
                  )
                );
                navigate(`/invoices/view-invoices`, {
                  state: { filters: { ...locationFilters } },
                });
              }
            })
            .catch((error) => {
              handleErrorState(error);
            })
            .finally(() => {
              setSubmitting(false);
            });
        } else {
          REQUEST_CREATE_INVOICE(invoicePayload)
            .then((res) => {
              const invoiceResponse = getBody(res);
              if (invoiceResponse?.success === true) {
                dispatch(
                  snackbarActions.showSnackbar(
                    invoiceResponse?.data?.message,
                    "success"
                  )
                );
                navigate(`/invoices/view-invoices`, {
                  state: { filters: { ...locationFilters } },
                });
              }
            })
            .catch((error) => {
              handleErrorState(error);
            })
            .finally(() => {
              setSubmitting(false);
            });
        }
      } else {
        REQUEST_GENERATE_INVOICE(data)
          .then((res) => {
            const generateInvoiceRes = getBody(res);
            if (generateInvoiceRes?.success === true) {
              const invoicePayload = new FormData();
              invoicePayload.append("client_id", values?.client || "");
              invoicePayload.append("project_id", values?.project || "");
              invoicePayload.append("proposal_id", values?.active || "");
              if (estimatedId) {
                invoicePayload.append("estimate_id", estimatedId || "");
              }
              invoicePayload.append("client_name", values?.other_client || "");
              invoicePayload.append("project_name", values?.other_project);
              if (values?.other_client || values?.other_project) {
                invoicePayload.append("is_external", 1);
              }
              invoicePayload.append("currency_id", values?.currency?.id);
              invoicePayload.append(
                "client_address",
                values?.client_address?.trim()
                  ? values?.client_address?.trim()
                  : ""
              );
              invoicePayload.append("company_id", values?.company || "");
              invoicePayload.append(
                "invoice_rate",
                Number(values?.invoice_amount)
              );
              invoicePayload.append("invoice_no", values?.invoice_number);
              invoicePayload.append('currency_rate', Number(values?.currency_rate) || 0)
              if (values?.invoice_date) {
                invoicePayload.append(
                  "invoice_date",
                  format(values?.invoice_date, "yyyy-MM-dd")
                );
              }
              if (values?.due_date) {
                invoicePayload.append(
                  "due_date",
                  format(values?.due_date, "yyyy-MM-dd")
                );
              }
              invoicePayload.append(
                "discount_label",
                values?.reduce_label?.trim() ? values?.reduce_label?.trim() : ""
              );
              invoicePayload.append(
                "discount_amount",
                Number(values?.reduce_amount) || 0
              );
              invoicePayload.append(
                "invoice_description",
                values?.job_description?.trim()
                  ? values?.job_description?.trim()
                  : ""
              );
              invoicePayload.append(
                "notice",
                values?.notice?.trim() ? values?.notice?.trim() : ""
              );
              invoicePayload.append("reference", values?.invoice_number || "");
              invoicePayload.append("hourly_rate", "");
              invoicePayload.append("expense_amount", "");
              invoicePayload.append("task_filter", "");
              invoicePayload.append("invoice_type", "invoice");
              invoicePayload.append("is_paid", values?.is_paid);
              invoicePayload.append(
                "work_info",
                JSON.stringify({
                  work_paid_amount: cleanedForm,
                  price_amount: Number(values?.work_price_amount),
                  is_paid: values?.is_paid,
                  is_completed: values?.is_completed,
                  ...(values?.work_start_date && {
                    work_start_date: format(
                      values?.work_start_date,
                      "yyyy-MM-dd"
                    ),
                  }),
                  ...(values?.work_end_date && {
                    work_end_date: format(values?.work_end_date, "yyyy-MM-dd"),
                  }),
                  ...(values?.work_title?.trimStart() && {
                    work_title: values?.work_title?.trimStart(),
                  }),
                })
              );

              if (values?.attachment) {
                Object.values(values?.attachment).forEach((fileData) => {
                  invoicePayload.append("attachment[]", fileData);
                });
              }

              if (Boolean(params?.invoiceId)) {
                invoicePayload.append("invoice_id", params?.invoiceId);

                REQUEST_UPDATE_INVOICE(invoicePayload)
                  .then((res) => {
                    const invoiceResponse = getBody(res);
                    if (invoiceResponse?.success === true) {
                      navigate("/invoices/preview-invoice", {
                        state: {
                          values: {
                            ...values,
                            isEdit: isEdit,
                            invoice_id: params?.invoiceId,
                          },
                          selectedCurrency: selectedCurrency,
                          selectedClient: selectedClients,
                          previewData: generateInvoiceRes?.data,
                          lastPath: "/invoices/add-invoice",
                          clientData: clientData,
                          estimatedId: estimatedId,
                        },
                      });
                    }
                  })
                  .catch((error) => {
                    handleErrorState(error);
                  })
                  .finally(() => {
                    setSubmitting(false);
                  });
              } else {
                REQUEST_CREATE_INVOICE(invoicePayload)
                  .then((res) => {
                    const invoiceResponse = getBody(res);
                    if (invoiceResponse?.success === true) {
                      navigate("/invoices/preview-invoice", {
                        state: {
                          values: {
                            ...values,
                            isEdit: isEdit,
                            invoice_id: invoiceResponse?.data?.invoice_id,
                          },
                          selectedCurrency: selectedCurrency,
                          selectedClient: selectedClients,
                          previewData: generateInvoiceRes?.data,
                          lastPath: "/invoices/add-invoice",
                          clientData: clientData,
                        },
                      });
                    }
                  })
                  .catch((error) => {
                    handleErrorState(error);
                  })
                  .finally(() => {
                    setSubmitting(false);
                  });
              }
            }
          })
          .catch((err) => {
            handleErrorState(err);
          })
          .finally(() => {
            setSubmitting(false);
          });
      }
    },
  });

  const getActiveProposalList = () => {

    REQUEST_ACTIVE_PROPOSAL_LIST()
      .then((response) => {
        response = getBody(response);
        if (response?.success === true) {
          setActiveProposals(response?.data);
        }
      })
      .catch((error) => {
        handleErrorState(error)
      })
  }

  useEffect(() => {
    getActiveProposalList()
  }, [])

  const getClientList = () => {
    setisClientLoading(true);
    REQUEST_GET_CLIENTS_LIST()
      .then(async (res) => {
        res = getBody(res);
        setisClientLoading(false);
        if (res.success === true) {
          await setClients(res.data);
        }
      })
      .catch((error) => {
        setisClientLoading(false);
        handleErrorState(error);
      });
  };

  const getProjects = () => {
    setIsProjectLoading(true);
    REQUEST_GET_PROJECTS_LIST_USER()
      .then(async (res) => {
        res = getBody(res);
        if (Boolean(res?.success) === true) {
          await setProjects(res?.data);
          dispatch(projectsActions.projects_list(res.data));
        }
      })
      .catch((error) => {
        handleErrorState(error);
      })
      .finally(() => {
        setIsProjectLoading(false);
      });
  };

  const getCurrency = () => {
    setisCurrencyLoading(true);
    REQUEST_GET_CURRENCY_LIST()
      .then(async (res) => {
        res = getBody(res);
        setisCurrencyLoading(false);
        if (res.success === true) {
          await setCurrency(res.data);
        }
      })
      .catch((error) => {
        setisCurrencyLoading(false);
        handleErrorState(error);
      });
  };

  const generateInvoiceNumber = async (
    clientName,
    clientId,
    invoiceDate,
    isUpdate
  ) => {
    let initials = "";
    if (clientName) {
      const words = clientName.split(" ");
      initials = words[0]?.charAt(0)?.toUpperCase() || "";
      if (words[1]) {
        initials += words[1].charAt(0).toUpperCase();
      }
    }

    const formattedDate = invoiceDate
      ? format(new Date(invoiceDate), "ddMMyyyy")
      : format(new Date(), "ddMMyyyy");
    let count = 0;
    try {
      const response = await REQUEST_GET_INVOICES_BY_DATE({
        date: formattedDate,
        clientId,
        clientName,
      });
      const invoiceData = getBody(response);
      if (invoiceData?.success === true) {
        count = Array.isArray(invoiceData.data) ? invoiceData.data.length : 0;
      }
    } catch (error) {
      handleErrorState(error);
    }

    if (isUpdate) {
      return `${initials}/${formattedDate}`;
    }
    return count > 0
      ? `${initials}/${count + 1}/${formattedDate}`
      : `${initials}/${formattedDate}`;
  };

  const getClientData = (id) => {
    REQUEST_GET_CLIENTS_DATA({ value: id })
      .then(async (res) => {
        res = getBody(res);
        if (res.success === true) {
          setClientData(res.data);
          setProjects(res?.data?.project);
          // if (generateInvoiceFormik?.values?.client) {
          const invoiceNumber = await generateInvoiceNumber(
            res.data.address?.client_name,
            id,
            generateInvoiceFormik.values.invoice_date,
            isEdit
          );
          generateInvoiceFormik.setFieldValue(
            "invoice_number",
            invoiceNumber
          );
          // }

          let combinedAddress = "";
          combinedAddress =
            res.data.address?.client_name &&
              res.data.company &&
              res.data.address?.address
              ? `${res.data.address.client_name} (${res.data.company})\n${res.data.address.address}`
              : res.data.address?.client_name && res.data.company
                ? `${res.data.address.client_name} (${res.data.company})`
                : res.data.address?.client_name
                  ? `${res.data.address.client_name}\n${res.data.address?.address || ""}`
                  : res.data.address?.address || "";
          generateInvoiceFormik.setFieldValue(
            "client_address",
            combinedAddress || ""
          );
          if (goBackValuePassState !== null) {
            setGoBackValuePassState((prev) => ({
              ...prev,
              client_address: combinedAddress,
            }));
          }
          generateInvoiceFormik.setFieldValue('currency_rate', res?.data?.currency_rate || 0)
        }
      })
      .catch((error) => {
        handleErrorState(error);
      });
  };

  const getCompanyList = (id) => {
    setisCompanyLoading(true);
    REQUEST_GET_COMPANY_LIST({ id })
      .then(async (res) => {
        res = getBody(res);
        setisCompanyLoading(false);
        if (res.success === true) {
          await setCompany(res.data);
        }
      })
      .catch((error) => {
        setisCompanyLoading(false);
        handleErrorState(error);
      });
  };

  const handleProjectChange = (_, newValue) => {
    if (!newValue) {
      setSelectedProject(newValue);
      generateInvoiceFormik.setFieldValue("project", newValue?.id);
      return;
    }

    setSelectedProject(newValue);
    const project_id = newValue?.id;
    generateInvoiceFormik.setFieldValue("project", project_id);
    generateInvoiceFormik.setFieldValue("other_project", "");
    REQUEST_PROJECT_CLIENT_DATA({ value: project_id })
      .then((res) => {
        res = getBody(res);
        if (res.success === true) {
          setSelectedClients({
            client_name: res?.data?.address?.client_name,
            id: res?.data?.address?.client_id,
          });
          setClientData(res?.data);
          generateInvoiceFormik.setFieldValue(
            "client",
            res?.data?.address?.client_id
          );
          generateInvoiceFormik.setFieldValue("other_client", "");
          let combinedAddress = "";
          combinedAddress =
            res.data.address?.client_name &&
              res.data.company &&
              res.data.address?.address
              ? `${res.data.address.client_name} (${res.data.company})\n${res.data.address.address}`
              : res.data.address?.client_name && res.data.company
                ? `${res.data.address.client_name} (${res.data.company})`
                : res.data.address?.client_name
                  ? `${res.data.address.client_name}\n${res.data.address?.address || ""}`
                  : res.data.address?.address || "";
          generateInvoiceFormik.setFieldValue(
            "client_address",
            combinedAddress
          );
          generateInvoiceFormik.setFieldValue(
            "client_address",
            combinedAddress || ""
          );
          generateInvoiceFormik.setFieldValue('currency_rate', res?.data?.currency_rate || 0)
        }
      })
      .catch((error) => {
        handleErrorState(error);
      });
  };

  const handleActiveChange = (_, newValue) => { // New handler for active proposal
    if (!newValue) {
      setSelectedActive(newValue);
      generateInvoiceFormik.setFieldValue("active", newValue?.id);
      return;
    }
    setSelectedActive(newValue);
    generateInvoiceFormik.setFieldValue("active", newValue?.id);
    // You can add more logic here if selecting active proposal affects other fields, like client or address
  };

  const handlePreviousData = () => {
    Object.keys(goBackValuePassState).map((key_param) => {
      generateInvoiceFormik.setFieldValue(
        key_param,
        goBackValuePassState[key_param]
      );
      return key_param;
    });
    if (goBackValuePassState?.client !== null) {
      setSelectedClients(
        clients?.filter(
          (client) => client?.id === goBackValuePassState?.client
        )[0]
      );
    }
    if (goBackValuePassState?.project !== null) {
      setSelectedProject(
        projects?.filter(
          (project) => project?.id === goBackValuePassState?.project
        )[0]
      );
    }
    if (goBackValuePassState?.company !== null) {
      setSelectedCompany(
        company?.filter((comp) => comp?.id === goBackValuePassState?.company)[0]
      );
    }
    if (goBackValuePassState?.currency !== null) {
      setSelectedCurrency(
        currency?.filter(
          (curr) => curr?.id === goBackValuePassState?.currency?.id
        )[0]
      );
    }

    if (goBackValuePassState?.active !== null) { // New: Handle previous active
      setSelectedActive(
        activeProposals?.filter(
          (prop) => prop?.id === goBackValuePassState?.active
        )[0]
      );
    }
  };

  useEffect(() => {
    if (EstimatedData) {
      getEditgetEditDataData(EstimatedData.id);
    }
  }, [EstimatedData])

  const getEditgetEditDataData = async (id) => {
    REQUEST_GET_EDIT_ESTIMATE({ id: id })
      .then(async (res) => {
        res = getBody(res);
        const editInvoiceResponse = res;
        if (res?.success === true) {
          if (editInvoiceResponse?.data?.client_id) {
            await getClientData(editInvoiceResponse?.data?.client_id);
          }
          setInvoiceData(editInvoiceResponse?.data);
          setEstimatedId(editInvoiceResponse?.data?.id)
          setSelectedProject({
            id: res?.data?.project_id,
            project_name: res?.data?.project,
          });
          generateInvoiceFormik.setFieldValue(
            "client",
            editInvoiceResponse?.data?.client_id
          );
          generateInvoiceFormik.setFieldValue(
            "other_client",
            editInvoiceResponse?.data?.other_client
          );
          generateInvoiceFormik.setFieldValue(
            "project",
            editInvoiceResponse?.data?.project_id
          );
          generateInvoiceFormik.setFieldValue(
            "other_project",
            editInvoiceResponse?.data?.other_project
          );
          generateInvoiceFormik.setFieldValue(
            "active",
            editInvoiceResponse?.data?.proposal_id || ""
          );
          generateInvoiceFormik.setFieldValue(
            "client_address",
            editInvoiceResponse?.data?.client_address
          );
          generateInvoiceFormik.setFieldValue(
            "company",
            editInvoiceResponse?.data?.company_id
          );
          // generateInvoiceFormik.setFieldValue(
          //   "invoice_amount",
          //   Number(editInvoiceResponse?.data?.invoice_rate)
          // );
          generateInvoiceFormik.setFieldValue(
            "work_price_amount",
            Number(editInvoiceResponse?.data?.amount)
          );
          
          //paid_amount data normlized Data
          const paidAmountData = invoiceDatas?.work_info?.work_paid_amount;
          const normlizedPaidAmount = normlizedPaidAmountData(paidAmountData, isCopy, isEdit);
          generateInvoiceFormik.setFieldValue("work_paid_amount", normlizedPaidAmount)
          
          generateInvoiceFormik.setFieldValue(
            "is_paid",
            Number(invoiceDatas?.work_info?.is_paid) || 0
          );
          generateInvoiceFormik.setFieldValue(
            "is_completed",
            Number(invoiceDatas?.work_info?.is_completed) || 0
          );
          generateInvoiceFormik.setFieldValue(
            "reduce_label",
            editInvoiceResponse?.data?.discount_label
          );
          if (editInvoiceResponse?.data?.work_info?.work_start_date) {
            generateInvoiceFormik.setFieldValue(
              "work_start_date",
              new Date(editInvoiceResponse?.data?.work_info?.work_start_date)
            );
          }
          if (editInvoiceResponse?.data?.work_info?.work_end_date) {
            generateInvoiceFormik.setFieldValue(
              "work_end_date",
              new Date(editInvoiceResponse?.data?.work_info?.work_end_date)
            );
          }
          generateInvoiceFormik.setFieldValue(
            "work_title",
            editInvoiceResponse?.data?.work_info?.work_title || ""
          );
          generateInvoiceFormik.setFieldValue(
            "reduce_amount",
            Number(editInvoiceResponse?.data?.discount_amount || 0)
          );
          generateInvoiceFormik.setFieldValue(
            "job_description",
            editInvoiceResponse?.data?.work_description
          );
          generateInvoiceFormik.setFieldValue(
            "notice",
            editInvoiceResponse?.data?.notice
          );
          generateInvoiceFormik.setFieldValue(
            "invoice_number",
            editInvoiceResponse?.data?.reference
          );
          generateInvoiceFormik?.setFieldError('currency_rate', Number(editInvoiceResponse?.currency_rate) || 0)
          setAttachment(editInvoiceResponse?.data?.attachments);
        }
      })
      .catch((error) => {
        handleErrorState(error);
      });
  };

  const fetchInvoiceDetails = (invoice_id) => {
    REQUEST_VIEW_INVOICE({ invoice_id })
      .then((res) => {
        const editInvoiceResponse = getBody(res);
        if (editInvoiceResponse?.success === true) {
          setInvoiceData(editInvoiceResponse?.data);
          generateInvoiceFormik.setFieldValue(
            "client",
            editInvoiceResponse?.data?.client_id
          );
          generateInvoiceFormik.setFieldValue(
            "other_client",
            editInvoiceResponse?.data?.client_name
          );
          generateInvoiceFormik.setFieldValue(
            "project",
            editInvoiceResponse?.data?.project_id
          );
          generateInvoiceFormik.setFieldValue(
            "active",
            editInvoiceResponse?.data?.proposal_id || ""
          );
          generateInvoiceFormik.setFieldValue(
            "other_project",
            editInvoiceResponse?.data?.project_name
          );
          generateInvoiceFormik.setFieldValue(
            "client_address",
            editInvoiceResponse?.data?.client_address
          );
          generateInvoiceFormik.setFieldValue(
            "company",
            editInvoiceResponse?.data?.company_id
          );
          generateInvoiceFormik.setFieldValue(
            "invoice_amount",
            Number(editInvoiceResponse?.data?.invoice_rate)
          );
          generateInvoiceFormik.setFieldValue(
            "work_price_amount",
            Number(editInvoiceResponse?.data?.work_info?.price_amount)
          );

          //paid_amount_code using Normlize data 
          const paidAmountData = editInvoiceResponse?.data?.work_info?.work_paid_amount;
          const normlizedPaidAmount = normlizedPaidAmountData(paidAmountData, isCopy, isEdit);
          generateInvoiceFormik.setFieldValue("work_paid_amount", normlizedPaidAmount)

          generateInvoiceFormik.setFieldValue(
            "is_paid",
            Number(invoiceDatas?.work_info?.is_paid ? invoiceDatas?.work_info?.is_paid : editInvoiceResponse?.data?.work_info?.is_paid) || 0
          );
          generateInvoiceFormik.setFieldValue(
            "is_completed",
            Number(invoiceDatas?.work_info?.is_completed ? invoiceDatas?.work_info?.is_completed : editInvoiceResponse?.data?.work_info?.is_completed) || 0
          );
          if (!isCopy) {
            generateInvoiceFormik.setFieldValue(
              "invoice_date",
              new Date(editInvoiceResponse?.data?.invoice_date)
            );
            generateInvoiceFormik.setFieldValue(
              "due_date",
              editInvoiceResponse?.data?.due_date && new Date(editInvoiceResponse?.data?.due_date)
            );
          }
          generateInvoiceFormik.setFieldValue(
            "reduce_label",
            editInvoiceResponse?.data?.discount_label
          );
          if (editInvoiceResponse?.data?.work_info?.work_start_date) {
            generateInvoiceFormik.setFieldValue(
              "work_start_date",
              new Date(editInvoiceResponse?.data?.work_info?.work_start_date)
            );
          }
          if (editInvoiceResponse?.data?.work_info?.work_end_date) {
            generateInvoiceFormik.setFieldValue(
              "work_end_date",
              new Date(editInvoiceResponse?.data?.work_info?.work_end_date)
            );
          }
          generateInvoiceFormik.setFieldValue(
            "work_title",
            editInvoiceResponse?.data?.work_info?.work_title || ""
          );
          generateInvoiceFormik.setFieldValue(
            "reduce_amount",
            Number(editInvoiceResponse?.data?.discount_amount)
          );
          generateInvoiceFormik.setFieldValue(
            "job_description",
            editInvoiceResponse?.data?.invoice_description
          );
          generateInvoiceFormik.setFieldValue(
            "notice",
            editInvoiceResponse?.data?.notice
          );
          if (isCopy) {
            generateInvoiceFormik.setFieldValue("invoice_number", "");
          } else {
            generateInvoiceFormik.setFieldValue(
              "invoice_number",
              editInvoiceResponse?.data?.reference
            );
          }
          generateInvoiceFormik.setFieldValue('currency_rate', Number(editInvoiceResponse?.data?.currency_rate || editInvoiceResponse?.data?.currency_rate_temp).toFixed(2) || 0)
          setAttachment(editInvoiceResponse?.data?.attachments);
        } else {
          console.error('[ERROR] fetchInvoiceDetails failed:', editInvoiceResponse?.message);
        }
      })
      .catch((err) => {
        handleErrorState(err);
      });
  };

  const handleCurrencyAutocompleteChange = async (_, newValue) => {
    setSelectedCurrency(newValue);
    generateInvoiceFormik.setFieldValue("currency", newValue);

    if (newValue?.id) {
      try {
        const response = await REQUEST_GET_CURRENCY_RATE({ currency_id: newValue.id });
        const currencyRateResponse = getBody(response);

        if (currencyRateResponse?.success === true) {
          generateInvoiceFormik.setFieldValue(
            "currency_rate",
            Number(currencyRateResponse?.data?.currency_rate) || 0
          );
        } else {
          dispatch(
            snackbarActions.showSnackbar(
              currencyRateResponse?.message || "Failed to fetch currency rate",
              "error"
            )
          );
          generateInvoiceFormik.setFieldValue("currency_rate", 0);
        }
      } catch (error) {
        handleErrorState(error);
        generateInvoiceFormik.setFieldValue("currency_rate", 0);
      }
    } else {
      generateInvoiceFormik.setFieldValue("currency_rate", 0);
    }
  };

  const handleComapnyAutocompleteChange = (_, newValue) => {
    setSelectedCompany(newValue);
    generateInvoiceFormik.setFieldValue("company", newValue?.id);
  };

  // const handleClientAutocompleteChange = async (_, newValue) => {
  //   if (!newValue) {
  //     setSelectedClients(newValue);
  //     generateInvoiceFormik.setFieldValue("client", newValue?.id);
  //     return;
  //   }

  //   setSelectedClients(newValue);
  //   generateInvoiceFormik.setFieldValue("client", newValue?.id);
  //   generateInvoiceFormik.setFieldValue("other_client", "");
  //   getClientData(newValue?.id);
  // };

  const handleClientAutocompleteChange = async (_, newValue) => {
    if (!newValue) {
      setSelectedProject(null);
      setSelectedClients(null);
      generateInvoiceFormik.setFieldValue("client", null);
      generateInvoiceFormik.setFieldValue("client_address", "");
      generateInvoiceFormik.setFieldValue("other_client", "");
      setInvoiceData((prev) => ({
        ...prev,
        client_id: null,
        client_name: "",
        project_id: null,
      }));
      if (goBackValuePassState !== null) {
        setGoBackValuePassState((prev) => ({
          ...prev,
          client: null,
        }));
      }
      return;
    }

    setSelectedClients(newValue);
    generateInvoiceFormik.setFieldValue("client", newValue?.id);
    generateInvoiceFormik.setFieldValue("other_client", "");
    setInvoiceData((prev) => ({
      ...prev,
      client_id: newValue?.id,
      client_name: newValue?.client_name,
    }));
    if (goBackValuePassState !== null) {
      setGoBackValuePassState((prev) => ({
        ...prev,
        client: newValue?.id,
      }));
    }
    await getClientData(newValue?.id);
  };

  const handleCloseDelete = () => {
    setIsDeleteOpen(false);
    setIsDeleteFile(null);
  };

  const handleDeleteAttachment = (file) => {
    let data = new FormData();
    data.append("id", params?.invoiceId);
    data.append("file_name", file?.name);
    REQUEST_INVOICE_DELETE_ATTACHMENT(data)
      .then((res) => {
        res = getBody(res);
        if (res.success === true) {
          dispatch(snackbarActions.showSnackbar(res.data.message, "success"));
          const filteredAttachments = attachment?.filter(
            (data) => data?.name !== file?.name
          );
          setAttachment(filteredAttachments);
          generateInvoiceFormik.setFieldValue(
            "attachment",
            filteredAttachments
          );
          handleCloseDelete();
        }
      })
      .catch((error) => {
        handleErrorState(error);
      });
  };

  useEffect(() => {
    if (
      !isCopy &&
      generateInvoiceFormik.values?.invoice_number === "" &&
      selectedClients?.id &&
      generateInvoiceFormik.values.invoice_date
    ) {
      generateInvoiceNumber(
        selectedClients.client_name,
        selectedClients.id,
        generateInvoiceFormik.values.invoice_date,
        isEdit
      ).then((invoiceNumber) => {
        generateInvoiceFormik.setFieldValue("invoice_number", invoiceNumber);
      });
    }
  }, [generateInvoiceFormik.values.invoice_date, selectedClients, isEdit, isCopy, EstimatedData]);

  useEffect(() => {
    if (hasPermission("generate_fix_invoice", Boolean(isEdit || invoiceDatas) ? 1 : 0)) {
      getClientList();
      getProjects();
      getCurrency();
      getCompanyList();
      getActiveProposalList()

      if (Boolean(isEdit) && params?.invoiceId || invoiceDatas && invoiceDatas?.id) {
        fetchInvoiceDetails(params?.invoiceId || invoiceDatas?.id);
      }
      setInvoiceData((prev) => ({
        ...prev,
        is_paid: 0,
        is_completed: 1,
      }))
    }
  }, [isEdit, params?.invoiceId, invoiceDatas, invoiceDatas?.id]);

  useEffect(() => {
    if (clientData && currency) {
      let filteredCurrency = currency?.find(
        (item) => item.currency === clientData.country?.currency
      );
      setSelectedCurrency(filteredCurrency || null);
      generateInvoiceFormik.setFieldValue("currency", filteredCurrency);
    }
  }, [clientData, currency]);

  useEffect(() => {
    if (
      invoiceData &&
      currency?.length > 0 &&
      projects?.length > 0 &&
      clients?.length > 0 &&
      company?.length > 0
    ) {
      if (invoiceData?.client_id !== null) {
        setSelectedClients(
          clients?.filter((client) => client?.id === invoiceData?.client_id)[0]
        );
      }

      if (invoiceData?.project_id !== null) {
        setSelectedProject(
          projects?.filter(
            (project) => project?.id === Number(invoiceData?.project_id)
          )[0]
        );
      }

      if (invoiceData?.currency_id !== null) {
        setSelectedCurrency(
          currency?.filter((curr) => curr?.id === invoiceData?.currency_id)[0]
        );
        generateInvoiceFormik.setFieldValue(
          "currency",
          currency?.filter((curr) => curr?.id === invoiceData?.currency_id)[0]
        );
      }

      if (invoiceData?.company_id !== null) {
        setSelectedCompany(
          company?.filter((comp) => comp?.id === invoiceData?.company_id)[0]
        );
      }

      if (invoiceData?.proposal_id !== null) { // New: Set selected active if proposal_id exists
        setSelectedActive(
          activeProposals?.filter(
            (prop) => prop?.id === Number(invoiceData?.proposal_id)
          )[0]
        );
      }
    }
  }, [currency, clients, projects, company, invoiceData, activeProposals]);

  useEffect(() => {
    if (
      goBackValuePassState &&
      currency?.length > 0 &&
      projects?.length > 0 &&
      clients?.length > 0 &&
      company?.length > 0
    ) {
      handlePreviousData();
    }
  }, [currency, clients, projects, company, goBackValuePassState, activeProposals]);

  return (
    <Page title={`Invoices: ${isEdit ? `Edit Invoice` : `Add Invoice`}`}>
      <Container maxWidth="xl">
        <Grid
          display={"flex"}
          flex={1}
          alignItems={"center"}
          justifyContent={"space-between"}
          sx={{ mb: 3 }}
        >
          <Typography variant="h4">
            {isEdit ? `Edit Invoice` : `Add Invoice`}
          </Typography>
          <Button
            variant="contained"
            color="secondary"
            size="large"
            sx={{ width: 120 }}
            onClick={() => {
              navigate(`/invoices/view-invoices`, {
                state: { filters: { ...locationFilters } },
              });
            }}
          >
            Back
          </Button>
        </Grid>
        <form onSubmit={generateInvoiceFormik.handleSubmit}>
          <Card sx={{ padding: 3 }}>
            <Grid>
              <Typography variant="h6">Work Info</Typography>
              <Spacer space={2} />
            </Grid>
            <Grid display={"flex"} flexDirection={"column"} gap={3}>
              <Grid
                display={"flex"}
                gap={3}
                flexDirection={{
                  lg: "row",
                  md: "row",
                  sm: "row",
                  xs: "column",
                }}
              >
                <AsyncAutocomplete
                  label="Select Project"
                  disablePortal
                  disableClearable={!selectedProject}
                  options={projects}
                  isLoading={isProjectLoading}
                  getOptionLabel={(option) =>
                    `${option?.project_name || option?.project}`
                  }
                  isOptionEqualToValue={(option, value) =>
                    Number(option?.id) === Number(value?.id)
                  }
                  value={selectedProject}
                  onChange={handleProjectChange}
                  renderOption={(props, option) => (
                    <Box component={"li"} {...props} key={Number(option?.id)}>
                      {option?.project_name || option?.project}
                    </Box>
                  )}
                  error={
                    generateInvoiceFormik?.touched?.project &&
                    generateInvoiceFormik?.errors?.project
                  }
                  helperText={
                    generateInvoiceFormik?.touched?.project &&
                    generateInvoiceFormik?.errors?.project
                  }
                />
                <AsyncAutocomplete
                  label="Select Client"
                  disablePortal
                  disableClearable={!selectedClients}
                  options={clients}
                  isLoading={isClientLoading}
                  getOptionLabel={(option) => `${option?.client_name}`}
                  isOptionEqualToValue={(option, value) =>
                    Number(option?.id) === Number(value?.id)
                  }
                  value={selectedClients}
                  onChange={handleClientAutocompleteChange}
                  renderOption={(props, option) => (
                    <Box component={"li"} {...props} key={Number(option?.id)}>
                      {option?.client_name}
                    </Box>
                  )}
                  InputProps={{
                    endAdornment: selectedClients && (
                      <InputAdornment position="end">
                        <IconButton
                          onClick={() => {
                            setSelectedClients(null);
                            selectedProject(null);
                            generateInvoiceFormik.setFieldValue("project", "");
                          }
                          }
                          edge="end"
                        >
                          <CloseIcon />
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                />

                <AsyncAutocomplete
                  label="Select Active Proposal" // Updated label for clarity
                  options={activeProposals}
                  disablePortal
                  disableClearable={!selectedActive}
                  isLoading={false} // Assuming no loading state, add if needed
                  getOptionLabel={(option) => `${option?.project_title}`}
                  isOptionEqualToValue={(option, value) =>
                    Number(option?.id) === Number(value?.id)
                  }
                  value={selectedActive}
                  onChange={handleActiveChange}
                  renderOption={(props, option) => (
                    <Box component={"li"} {...props} key={Number(option?.id)}>
                      {option?.project_title}
                    </Box>
                  )}
                  error={
                    generateInvoiceFormik?.touched?.active &&
                    generateInvoiceFormik?.errors?.active
                  }
                  helperText={
                    generateInvoiceFormik?.touched?.active &&
                    generateInvoiceFormik?.errors?.active
                  }
                />
              </Grid>
              {(!selectedProject || !selectedClients) && (
                <Grid
                  display={"flex"}
                  gap={3}
                  flexDirection={{
                    lg: "row",
                    md: "row",
                    sm: "row",
                    xs: "column",
                  }}
                >
                  {!selectedProject && (
                    <TextField
                      name="other_project"
                      value={generateInvoiceFormik?.values?.other_project}
                      fullWidth
                      label="Other Project"
                      onChange={generateInvoiceFormik.handleChange}
                      error={
                        generateInvoiceFormik?.touched?.other_project &&
                        generateInvoiceFormik?.errors?.other_project
                      }
                      helperText={
                        generateInvoiceFormik?.touched?.other_project &&
                        generateInvoiceFormik?.errors?.other_project
                      }
                      disabled={selectedProject}
                    />
                  )}
                  {!selectedClients && (
                    <TextField
                      name="other_client"
                      value={generateInvoiceFormik?.values?.other_client}
                      fullWidth
                      label="Other Client"
                      onChange={generateInvoiceFormik.handleChange}
                      error={
                        generateInvoiceFormik?.touched?.other_client &&
                        generateInvoiceFormik?.errors?.other_client
                      }
                      helperText={
                        generateInvoiceFormik?.touched?.other_client &&
                        generateInvoiceFormik?.errors?.other_client
                      }
                      disabled={selectedClients}
                    />
                  )}
                </Grid>
              )}
              <Grid
                display={"flex"}
                gap={3}
                flexDirection={{
                  lg: "row",
                  md: "row",
                  sm: "row",
                  xs: "column",
                }}
              >
                <Grid display={"flex"} flex={1}>
                  <TextField
                    name="client_address"
                    multiline
                    rows={4.7}
                    fullWidth
                    label="Client Address"
                    onChange={generateInvoiceFormik.handleChange}
                    value={generateInvoiceFormik?.values?.client_address || ""}

                    error={
                      generateInvoiceFormik?.touched?.client_address &&
                      generateInvoiceFormik?.errors?.client_address
                    }
                    helperText={
                      generateInvoiceFormik?.touched?.client_address &&
                      generateInvoiceFormik?.errors?.client_address
                    }
                  />
                </Grid>
                <Grid
                  display={"flex"}
                  flex={1}
                  flexDirection={"column"}
                  gap={3}
                >
                  <AsyncAutocomplete
                    label="Select Bank"
                    options={company}
                    isLoading={isCompanyLoading}
                    disablePortal
                    disableClearable={!selectedCompany}
                    getOptionLabel={(option) => `${option?.display_name}`}
                    value={selectedCompany}
                    onChange={handleComapnyAutocompleteChange}
                    isOptionEqualToValue={(option, value) =>
                      option?.id === value?.id
                    }
                    renderOption={(props, option) => (
                      <Box component={"li"} {...props} key={Number(option?.id)}>
                        {option?.display_name}
                      </Box>
                    )}
                  />
                  <AsyncAutocomplete
                    label="Select Currency"
                    options={currency}
                    isLoading={isCurrencyLoading}
                    disablePortal
                    disableClearable={!selectedCurrency}
                    getOptionLabel={(option) =>
                      `${option?.name} (${option?.currency})`
                    }
                    value={selectedCurrency}
                    isOptionEqualToValue={(option, value) =>
                      Number(option?.id) === Number(value?.id)
                    }
                    onChange={handleCurrencyAutocompleteChange}
                    error={
                      generateInvoiceFormik.touched?.invoice_amount &&
                      generateInvoiceFormik.errors?.currency
                    }
                    helperText={
                      generateInvoiceFormik.touched?.invoice_amount &&
                      generateInvoiceFormik.errors?.currency
                    }
                  />
                </Grid>
              </Grid>
              <Grid
                display={"flex"}
                gap={3}
                flexDirection={{
                  lg: "row",
                  md: "row",
                  sm: "row",
                  xs: "column",
                }}
              >
                <Grid display={"flex"} flex={1}>
                  <TextField
                    name="work_price_amount"
                    value={generateInvoiceFormik?.values?.work_price_amount}
                    fullWidth
                    label="Work Total Amount"
                    type="number"
                    onChange={(e) => {
                      const value = Number(e?.target?.value || 0);
                      generateInvoiceFormik?.setFieldValue(
                        "work_price_amount",
                        Number(e?.target?.value || 0)?.toString() || 0
                      )
                      generateInvoiceFormik.setFieldValue(
                        "invoice_amount",
                        value.toString() || 0
                      );
                    }}
                    error={
                      generateInvoiceFormik?.touched?.work_price_amount &&
                      generateInvoiceFormik?.errors?.work_price_amount
                    }
                    helperText={
                      generateInvoiceFormik?.touched?.work_price_amount &&
                      generateInvoiceFormik?.errors?.work_price_amount
                    }
                    onWheel={(e) => e.target.blur()}
                  />
                </Grid>
                <Grid display={"flex"} flex={1}
                  onClick={(event) => {
                    event.stopPropagation();
                  }}
                >
                  <TextField
                    name="work_title"
                    value={generateInvoiceFormik?.values?.work_title}
                    fullWidth
                    label="Work Title"
                    onChange={generateInvoiceFormik.handleChange}
                    error={
                      generateInvoiceFormik?.touched?.work_title &&
                      generateInvoiceFormik?.errors?.work_title
                    }
                    helperText={
                      generateInvoiceFormik?.touched?.work_title &&
                      generateInvoiceFormik?.errors?.work_title
                    }
                  />
                </Grid>
              </Grid>
              {
                Array.isArray(generateInvoiceFormik?.values?.work_paid_amount) ? (
                  generateInvoiceFormik?.values?.work_paid_amount?.map((field, index) => (
                    <Grid
                      key={index}
                      display={"flex"}
                      alignItems={
                        generateInvoiceFormik?.errors?.work_paid_amount?.[index]?.paid_amount
                          ? "flex-start"
                          : "center"
                      }
                      flex={2}
                      gap={3}
                      justifyContent={"center"}
                      flexDirection={{
                        lg: "row",
                        md: "row",
                        sm: "row",
                        xs: "column",
                      }}
                    >
                      <Grid display={"flex"} fullWidth width={{ xs: "100%" }} flex={1} onClick={(event) => event.stopPropagation()}>
                        <TextField
                          name={`work_paid_amount[${index}].paid_amount`}
                          value={field.paid_amount ?? ""}
                          fullWidth
                          label="Work Paid Amount"
                          type="number"
                          onChange={(e) => {
                            const value = Number(e?.target?.value || 0);

                            generateInvoiceFormik?.setFieldValue(
                              `work_paid_amount[${index}].paid_amount`,
                              value || 0
                            );

                            generateInvoiceFormik?.setFieldValue(
                              "is_paid",
                              value < Number(generateInvoiceFormik?.values?.work_price_amount) && value !== 0
                                ? 2
                                : value === Number(generateInvoiceFormik?.values?.work_price_amount)
                                  ? 1
                                  : 0
                            );
                          }}
                          error={
                            generateInvoiceFormik?.touched?.work_paid_amount?.[index]?.paid_amount &&
                            Boolean(generateInvoiceFormik?.errors?.work_paid_amount?.[index]?.paid_amount)
                          }
                          helperText={
                            generateInvoiceFormik?.touched?.work_paid_amount?.[index]?.paid_amount &&
                            generateInvoiceFormik?.errors?.work_paid_amount?.[index]?.paid_amount
                          }
                          onWheel={(e) => e.target.blur()}
                        />
                      </Grid>

                      <Grid display={"flex"} fullWidth width={{ xs: "100%" }} flex={1} onClick={(event) => event.stopPropagation()}>
                        <CustomDatePicker
                          name={`work_paid_amount[${index}].date`}
                          fullWidth
                          label="Date"
                          onChange={(newValue) => {
                            if (newValue && isValid(new Date(newValue))) {
                              generateInvoiceFormik?.setFieldValue(
                                `work_paid_amount[${index}].date`,
                                format(new Date(newValue), "yyyy-MM-dd")
                              );
                            } else {
                              generateInvoiceFormik?.setFieldValue(`work_paid_amount[${index}].date`, null);
                            }
                          }}
                          hasValidation={true}
                          value={field?.date ? new Date(field.date) : null}
                          touched={generateInvoiceFormik?.touched?.work_paid_amount?.[index]?.date}
                          error={generateInvoiceFormik?.errors?.work_paid_amount?.[index]?.date}
                        />
                      </Grid>

                      <Grid display={"flex"} fullWidth width={{ xs: "100%" }} flex={1} onClick={(event) => event.stopPropagation()}>
                        <TextField
                          name={`work_paid_amount[${index}].note`}
                          label="Note"
                          fullWidth
                          onChange={(e) => {
                            generateInvoiceFormik?.setFieldValue(
                              `work_paid_amount[${index}].note`,
                              e?.target?.value || ""
                            );
                          }}
                          value={field.note || ""}
                        />
                      </Grid>

                      <Grid display={"flex"} flex={0.1} onClick={(event) => event.stopPropagation()}>
                        {index === generateInvoiceFormik?.values?.work_paid_amount?.length - 1 ? (
                          <IconButtonTooltip
                            title={"Add"}
                            icon={<AddCircle color="secondary" fontSize="medium" />}
                            onClick={() => {
                              const newField = {
                                paid_amount: 0,
                                date: null,
                                note: "",
                              };
                              generateInvoiceFormik?.setFieldValue("work_paid_amount", [
                                ...generateInvoiceFormik?.values?.work_paid_amount,
                                newField,
                              ]);
                            }}
                          />
                        ) : (
                          <IconButtonTooltip
                            title={"Remove"}
                            icon={<DoNotDisturbOnIcon color="error" fontSize="medium" />}
                            onClick={() => handleRemovePaidAmount(index)}
                          />
                        )}
                      </Grid>
                    </Grid>
                  ))
                )
                  :
                  (
                    <Typography>No Payment Data Avalable</Typography>
                  )
              }
              <Grid
                display={"flex"}
                gap={3}
                flexDirection={{
                  lg: "row",
                  md: "row",
                  sm: "row",
                  xs: "column",
                }}
              >
                <Grid display={"flex"} flex={1}>
                  <CustomDatePicker
                    name="work_start_date"
                    label="Work Start Date"
                    value={generateInvoiceFormik?.values?.work_start_date}
                    sx={{ width: "100%" }}
                    fullWidth={true}
                    onChange={(newValue) =>
                      generateInvoiceFormik.setFieldValue(
                        "work_start_date",
                        newValue
                      )
                    }
                    hasValidation={false}
                  />
                </Grid>
                <Grid display={"flex"} flex={1}>
                  <CustomDatePicker
                    name="work_end_date"
                    label="Work End Date"
                    value={generateInvoiceFormik?.values?.work_end_date}
                    sx={{ width: "100%" }}
                    fullWidth={true}
                    onChange={(newValue) =>
                      generateInvoiceFormik.setFieldValue(
                        "work_end_date",
                        newValue
                      )
                    }
                    hasValidation={false}
                  />
                </Grid>
              </Grid>
              <Grid
                display={"flex"}
                gap={3}
                flexDirection={{
                  lg: "row",
                  md: "row",
                  sm: "row",
                  xs: "column",
                }}
              >
                <Grid display={"flex"} flex={1}>
                  <FormControl sx={{ pl: 1 }}>
                    <FormLabel id="demo-row-radio-buttons-group-label">
                      Is paid
                    </FormLabel>
                    <RadioGroup
                      row
                      aria-labelledby="demo-row-radio-buttons-group-label"
                      name="is_paid"
                      onChange={generateInvoiceFormik.handleChange}
                      value={generateInvoiceFormik?.values?.is_paid}
                      sx={{ display: "flex", gap: 5 }}
                    >
                      <FormControlLabel
                        value={0}
                        control={<Radio />}
                        label="No"
                      />
                      <FormControlLabel
                        value={1}
                        control={<Radio />}
                        label="Yes"
                      />
                      <FormControlLabel
                        value={2}
                        control={<Radio disabled />}
                        label="Partially"
                      />
                    </RadioGroup>
                  </FormControl>
                </Grid>
                <Grid display={"flex"} flex={1}>
                  <FormControl sx={{ pl: 1 }}>
                    <FormLabel id="demo-row-radio-buttons-group-label">
                      Is completed
                    </FormLabel>
                    <RadioGroup
                      row
                      aria-labelledby="demo-row-radio-buttons-group-label"
                      name="is_completed"
                      onChange={generateInvoiceFormik.handleChange}
                      value={generateInvoiceFormik?.values?.is_completed}
                      sx={{ display: "flex", gap: 5 }}
                    >
                      <FormControlLabel
                        value={0}
                        control={<Radio />}
                        label="Pending"
                      />
                      <FormControlLabel
                        value={1}
                        control={<Radio />}
                        label="Completed"
                      />
                    </RadioGroup>
                  </FormControl>
                </Grid>
              </Grid>
              <Grid
                display={"flex"}
                gap={3}
                flexDirection={{
                  lg: "row",
                  md: "row",
                  sm: "row",
                  xs: "column",
                }}
              >
                <Grid display={"flex"} flex={1}>
                  <TextField
                    name="job_description"
                    multiline
                    rows={10}
                    fullWidth
                    label={"Description"}
                    value={generateInvoiceFormik.values.job_description}
                    onChange={generateInvoiceFormik.handleChange}
                    error={
                      generateInvoiceFormik.touched.job_description &&
                      generateInvoiceFormik.errors.job_description
                    }
                    helperText={
                      generateInvoiceFormik.touched.job_description &&
                      generateInvoiceFormik.errors.job_description
                    }
                  />
                </Grid>
                <Grid
                  display={"flex"}
                  flex={1}
                  gap={3}
                  flexDirection={"column"}
                >
                  <Stack>
                    <LabelStyle>Attachments</LabelStyle>
                    <MultipleUploadInput
                      formRef={{ current: generateInvoiceFormik }}
                      selectedAttachments={attachment}
                      acceptFormats={
                        "image/*, .pdf, .doc, .docx, .txt, .svg, .xlsx, .xls, .zip,.rar,application/octet-stream"
                      }
                    />
                    <Spacer space={2} />
                    {attachment?.length > 0 && (
                      <>
                        <LabelStyle>Files</LabelStyle>
                        <Box
                          sx={{
                            padding: 1.5,
                            border: "1px solid lightgray",
                            borderRadius: 1,
                          }}
                        >
                          {attachment?.map((file, ind) => (
                            <React.Fragment key={ind}>
                              <Stack
                                direction={"row"}
                                justifyContent={"space-between"}
                                alignItems={"center"}
                                sx={{ display: { xs: "block", sm: "flex" } }}
                              >
                                <Typography>{file?.name}</Typography>
                                <Stack direction={"row"} spacing={1}>
                                  <Button
                                    variant="outlined"
                                    size="small"
                                    id="file_download"
                                    onClick={() => {
                                      if (file?.downloadlink) {
                                        downloadFile(
                                          file?.downloadlink,
                                          file?.name
                                        );
                                      }
                                    }}
                                  >
                                    Download
                                  </Button>
                                  <Button
                                    variant="outlined"
                                    color="error"
                                    size="small"
                                    onClick={() => {
                                      setIsDeleteOpen(true);
                                      setIsDeleteFile(file);
                                    }}
                                  >
                                    Delete
                                  </Button>
                                </Stack>
                              </Stack>
                              {Boolean(attachment?.length - 1 !== ind) && (
                                <Divider
                                  sx={{
                                    borderStyle: "dashed",
                                    borderWidth: 1,
                                    borderColor: "text.secondary",
                                    marginY: 1,
                                  }}
                                />
                              )}
                            </React.Fragment>
                          ))}
                        </Box>
                      </>
                    )}
                  </Stack>
                </Grid>
              </Grid>
            </Grid>
          </Card>
          <Spacer space={2} />
          <Card sx={{ padding: 3 }}>
            <Grid>
              <Typography variant="h6">Invoice Info</Typography>
              <Spacer space={2} />
            </Grid>
            <Grid display={"flex"} flexDirection={"column"} gap={3}>
              <Grid
                display={"flex"}
                gap={3}
                flexDirection={{
                  lg: "row",
                  md: "row",
                  sm: "row",
                  xs: "column",
                }}
              >
                <Grid display={"flex"} flex={1}>
                  <CustomDatePicker
                    name="invoice_date"
                    label="Invoice Date"
                    value={generateInvoiceFormik.values.invoice_date}
                    sx={{ width: "100%" }}
                    fullWidth={true}
                    onChange={(newValue) =>
                      generateInvoiceFormik.setFieldValue(
                        "invoice_date",
                        newValue
                      )
                    }
                    hasValidation={false}
                  />
                </Grid>
                <Grid display={"flex"} flex={1}>
                  <CustomDatePicker
                    name="due_date"
                    label="Due Date"
                    value={generateInvoiceFormik.values.due_date}
                    sx={{ width: "100%" }}
                    fullWidth={true}
                    onChange={(newValue) =>
                      generateInvoiceFormik.setFieldValue("due_date", newValue)
                    }
                    hasValidation={false}
                  />
                </Grid>
              </Grid>
              <Grid
                display={"flex"}
                gap={3}
                flexDirection={{
                  lg: "row",
                  md: "row",
                  sm: "row",
                  xs: "column",
                }}
              >
                <Grid display={"flex"} flex={1}>
                  <TextField
                    name="notice"
                    fullWidth
                    multiline
                    rows={4.7}
                    label="Notice"
                    onChange={generateInvoiceFormik.handleChange}
                    value={generateInvoiceFormik.values.notice}
                  />
                </Grid>
                <Grid
                  display={"flex"}
                  flex={1}
                  flexDirection={"column"}
                  gap={2}
                >
                  <Grid display={"flex"} alignItems={"center"} gap={2} flexDirection={{ xs: "column", sm: "column", md: "row" }}>
                    <TextField
                      name="invoice_number"
                      value={generateInvoiceFormik?.values?.invoice_number}
                      fullWidth
                      label="Invoice Number"
                      onChange={(e) =>
                        generateInvoiceFormik?.setFieldValue(
                          "invoice_number",
                          e.target.value
                        )
                      }
                      error={
                        generateInvoiceFormik?.touched?.invoice_number &&
                        generateInvoiceFormik?.errors?.invoice_number
                      }
                      helperText={
                        generateInvoiceFormik?.touched?.invoice_number &&
                        generateInvoiceFormik?.errors?.invoice_number
                      }
                    />
                    <TextField
                      name="currency_rate"
                      value={generateInvoiceFormik?.values?.currency_rate || ""}
                      fullWidth
                      label="Currency rate"
                      onChange={(e) =>
                        generateInvoiceFormik?.setFieldValue(
                          "currency_rate",
                          e.target.value
                        )}
                      error={
                        generateInvoiceFormik?.touched?.currency_rate &&
                        generateInvoiceFormik?.errors?.currency_rate
                      }
                      helperText={
                        generateInvoiceFormik?.touched?.currency_rate &&
                        generateInvoiceFormik?.errors?.currency_rate
                      }
                    />
                  </Grid>
                  <TextField
                    name="invoice_amount"
                    value={generateInvoiceFormik?.values?.invoice_amount}
                    fullWidth
                    label="Invoice Amount"
                    type="number"
                    onChange={(e) =>
                      generateInvoiceFormik?.setFieldValue(
                        "invoice_amount",
                        Number(e?.target?.value || 0)?.toString() || 0
                      )
                    }
                    error={
                      generateInvoiceFormik?.touched?.invoice_amount &&
                      generateInvoiceFormik?.errors?.invoice_amount
                    }
                    helperText={
                      generateInvoiceFormik?.touched?.invoice_amount &&
                      generateInvoiceFormik?.errors?.invoice_amount
                    }
                    onWheel={(e) => e.target.blur()}
                  />
                </Grid>
              </Grid>
              <Grid
                display={"flex"}
                gap={3}
                flexDirection={{
                  lg: "row",
                  md: "row",
                  sm: "row",
                  xs: "column",
                }}
              >
                <Grid display={"flex"} flex={1}>
                  <TextField
                    label={"Discount Label"}
                    value={generateInvoiceFormik.values.reduce_label}
                    fullWidth
                    name="reduce_label"
                    onChange={generateInvoiceFormik.handleChange}
                  />
                </Grid>
                <Grid display={"flex"} flex={1}>
                  <TextField
                    name="reduce_amount"
                    fullWidth
                    label="Discount Amount"
                    onChange={generateInvoiceFormik.handleChange}
                    value={generateInvoiceFormik.values.reduce_amount}
                    error={
                      generateInvoiceFormik.touched.reduce_amount &&
                      generateInvoiceFormik.errors.reduce_amount
                    }
                    helperText={
                      generateInvoiceFormik.touched.reduce_amount &&
                      generateInvoiceFormik.errors.reduce_amount
                    }
                  />
                </Grid>
              </Grid>
            </Grid>
          </Card>
          <Spacer space={3} />
          <Grid display={"flex"} flex={1} justifyContent={"center"} gap={2}>
            <Button
              variant="contained"
              size="large"
              type="submit"
              onClick={() => {
                setGenerateState("save_invoice");
                generateInvoiceFormik.handleSubmit();
              }}
              disabled={
                !generateInvoiceFormik.dirty ||
                generateInvoiceFormik.isSubmitting
              }
            >
              {`Save Invoice`}
            </Button>
            <Button
              variant="contained"
              size="large"
              type="submit"
              onClick={() => {
                setGenerateState("generate_save");
                generateInvoiceFormik.handleSubmit();
              }}
              disabled={
                !generateInvoiceFormik.dirty ||
                generateInvoiceFormik.isSubmitting
              }
            >
              {`Generate & Save Invoice`}
            </Button>
          </Grid>
        </form>
        <ConfirmationDialog
          open={isDeleteOpen}
          action={() => handleDeleteAttachment(isDeleteFile)}
          actionText={"Delete"}
          headerMsg={"Delete Attachment"}
          message={"Are you sure you want to delete attachment?"}
          handleClose={handleCloseDelete}
          displayIcon={true}
        />
      </Container>
    </Page>
  );
};

export default AddInvoice;